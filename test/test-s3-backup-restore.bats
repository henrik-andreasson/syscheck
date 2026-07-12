#!/usr/bin/env bats
#
# Self-contained tests for 941_make_mysql_db_backup_and_transfer_to_s3.sh
# and 942_restore_mysql_db_from_s3.sh.
#
# curl is stubbed with a fake implementation that stores/serves objects on
# the local filesystem instead of talking to a real S3 endpoint, so these
# tests need no network access or S3 credentials. 904 (produces the local
# backup) and 920 (consumes the restored file) are stubbed too, so only
# 941/942 themselves are under test. Real gpg is used for the encryption
# tests, skipped if gpg isn't installed.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
	TEST_HOME="$(mktemp -d)"
	FAKE_S3_ROOT="$(mktemp -d)"
	FAKE_BIN="$(mktemp -d)"

	mkdir -p "$TEST_HOME"/related-available "$TEST_HOME"/config "$TEST_HOME"/lang "$TEST_HOME"/lib "$TEST_HOME"/var
	cp "$REPO_ROOT"/lib/*.sh "$TEST_HOME/lib/"
	cp "$REPO_ROOT/lang/common.english" "$TEST_HOME/lang/"
	cp "$REPO_ROOT/lang/941.english" "$TEST_HOME/lang/"
	cp "$REPO_ROOT/lang/942.english" "$TEST_HOME/lang/"
	cp "$REPO_ROOT/config/common.conf" "$TEST_HOME/config/"
	cp "$REPO_ROOT/config/related-scripts.conf" "$TEST_HOME/config/"
	cp "$REPO_ROOT/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" "$TEST_HOME/related-available/"
	cp "$REPO_ROOT/related-available/942_restore_mysql_db_from_s3.sh" "$TEST_HOME/related-available/"
	chmod +x "$TEST_HOME"/related-available/*.sh
	touch "$TEST_HOME/syscheck.sh"

	# stub for 904_make_mysql_db_backup.sh: 941 shells out to this to
	# produce the local backup file it then uploads
	cat > "$TEST_HOME/related-available/904_make_mysql_db_backup.sh" <<EOF
#!/bin/bash
echo "$TEST_HOME/backup.gz"
exit 0
EOF
	chmod +x "$TEST_HOME/related-available/904_make_mysql_db_backup.sh"
	echo "fake sql dump content" > "$TEST_HOME/backup.gz"

	# stub for 920_restore_mysql_db_from_backup.sh: 942 hands the
	# downloaded/decrypted file off to this. Records what it was called
	# with and the content of the file it received so tests can assert
	# on them, and exits with $STUB920_EXITCODE (default 0).
	cat > "$TEST_HOME/related-available/920_restore_mysql_db_from_backup.sh" <<'EOF'
#!/bin/bash
echo "STUB920_ARGS:$@"
BACKUPFILE=""
prev=""
for a in "$@"; do
	[ "$prev" = "--backupfile" ] && BACKUPFILE="$a"
	prev="$a"
done
if [ -n "$BACKUPFILE" ]; then
	echo "STUB920_CONTENT:$(cat "$BACKUPFILE")"
fi
exit "${STUB920_EXITCODE:-0}"
EOF
	chmod +x "$TEST_HOME/related-available/920_restore_mysql_db_from_backup.sh"

	echo "PGP_PASSPHRASE_FILE=" > "$TEST_HOME/config/942.conf"

	# fake curl: services the --upload-file / --output S3 calls made by
	# 941/942 against a local directory tree instead of a real endpoint.
	# Buckets listed in FAKE_S3_FAIL_BUCKETS simulate an S3 error.
	cat > "$FAKE_BIN/curl" <<'EOF'
#!/bin/bash
ARGS=("$@")
URL="${ARGS[-1]}"
UPLOADFILE=""
DOWNLOADOUT=""
HEADERFILE=""

i=0
while [ $i -lt ${#ARGS[@]} ]; do
	case "${ARGS[$i]}" in
		--upload-file)  UPLOADFILE="${ARGS[$((i+1))]}" ; i=$((i+2));;
		--output)       DOWNLOADOUT="${ARGS[$((i+1))]}" ; i=$((i+2));;
		--dump-header)  HEADERFILE="${ARGS[$((i+1))]}" ; i=$((i+2));;
		*) i=$((i+1));;
	esac
done

PATHPART="${URL#*://}"
PATHPART="${PATHPART#*/}"
BUCKET="${PATHPART%%/*}"
OBJECTKEY="${PATHPART#*/}"
STORE="${FAKE_S3_ROOT}/${BUCKET}/${OBJECTKEY}"

for FAILB in ${FAKE_S3_FAIL_BUCKETS} ; do
	if [ "x${BUCKET}" = "x${FAILB}" ] ; then
		echo '<Error><Code>AccessDenied</Code></Error>' 1>&2
		exit 22
	fi
done

if [ "x${UPLOADFILE}" != "x" ] ; then
	mkdir -p "$(dirname "${STORE}")"
	cp "${UPLOADFILE}" "${STORE}"
	if [ "x${HEADERFILE}" != "x" ] ; then
		printf 'HTTP/1.1 200 OK\r\nETag: "fakeetag-%s"\r\n\r\n' "${BUCKET}" > "${HEADERFILE}"
	fi
	exit 0
elif [ "x${DOWNLOADOUT}" != "x" ] ; then
	if [ ! -f "${STORE}" ] ; then
		echo "404 not found" 1>&2
		exit 22
	fi
	cp "${STORE}" "${DOWNLOADOUT}"
	exit 0
fi

exit 1
EOF
	chmod +x "$FAKE_BIN/curl"

	export TEST_HOME FAKE_S3_ROOT
	export PATH="$FAKE_BIN:$PATH"
	export SYSCHECK_HOME="$TEST_HOME"
	export FAKE_S3_FAIL_BUCKETS=""
}

teardown() {
	if [ -n "$GNUPGHOME" ] && [ -d "$GNUPGHOME" ] ; then
		gpgconf --homedir "$GNUPGHOME" --kill gpg-agent >/dev/null 2>&1
	fi
	rm -rf "$TEST_HOME" "$FAKE_S3_ROOT" "$FAKE_BIN"
}

write_941_conf() {
	# $1 = S3 destination(s) config appended after the common defaults
	cat > "$TEST_HOME/config/941.conf" <<EOF
SUBDIR_DEFAULT=default
SUBDIR_DAILY=daily
SUBDIR_WEEKLY=weekly
SUBDIR_MONTHLY=monthly
SUBDIR_YEARLY=yearly
REMOVE_LOCAL_BACKUP=0
PGP_ENCRYPT_BACKUP=0
PGP_PUBKEY_FILE[0]=
$1
EOF
}

@test "941 uploads a backup to a single S3 destination" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default
	[ "$status" -eq 0 ]
	[[ "$output" == *"9411"* ]]

	uploaded=$(find "$FAKE_S3_ROOT/bucket-a/mysql/default" -type f)
	[ -n "$uploaded" ]
	[ "$(cat "$uploaded")" = "fake sql dump content" ]

	# no --remove-local: local backup must survive
	[ -f "$TEST_HOME/backup.gz" ]
}

@test "941 --remove-local deletes the local file after a successful upload" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default --remove-local
	[ "$status" -eq 0 ]
	[ ! -f "$TEST_HOME/backup.gz" ]
}

@test "941 uploads to every configured S3 destination" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret

S3_ENDPOINT[1]=http://fakes3.test
S3_REGION[1]=us-east-1
S3_BUCKET[1]=bucket-b
S3_PREFIX[1]=mysql
S3_ACCESS_KEY[1]=key
S3_SECRET_KEY[1]=secret
'
	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default
	[ "$status" -eq 0 ]
	[ -n "$(find "$FAKE_S3_ROOT/bucket-a/mysql/default" -type f)" ]
	[ -n "$(find "$FAKE_S3_ROOT/bucket-b/mysql/default" -type f)" ]
}

@test "941 --remove-local keeps the local file when any destination fails" {
	export FAKE_S3_FAIL_BUCKETS="bucket-b"
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret

S3_ENDPOINT[1]=http://fakes3.test
S3_REGION[1]=us-east-1
S3_BUCKET[1]=bucket-b
S3_PREFIX[1]=mysql
S3_ACCESS_KEY[1]=key
S3_SECRET_KEY[1]=secret
'
	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default --remove-local
	[ "$status" -eq 0 ]
	[[ "$output" == *"9413"* ]]
	[ -n "$(find "$FAKE_S3_ROOT/bucket-a/mysql/default" -type f)" ]
	[ -f "$TEST_HOME/backup.gz" ]
}

@test "941 --encrypt uploads one file that any of several PGP recipients can decrypt" {
	command -v gpg >/dev/null 2>&1 || skip "gpg not installed"

	export GNUPGHOME="$TEST_HOME/gnupghome"
	mkdir -p -m 700 "$GNUPGHOME"

	for who in one two; do
		cat > "$TEST_HOME/keyparams-$who" <<EOF
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Test $who
Name-Email: $who@example.com
Expire-Date: 1d
%commit
EOF
		gpg --batch --gen-key "$TEST_HOME/keyparams-$who" >/dev/null 2>&1
		gpg --batch --yes --export --armor "$who@example.com" > "$TEST_HOME/pubkey-$who.asc"
	done

	write_941_conf "
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
PGP_PUBKEY_FILE[0]=$TEST_HOME/pubkey-one.asc
PGP_PUBKEY_FILE[1]=$TEST_HOME/pubkey-two.asc
"

	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default --encrypt
	[ "$status" -eq 0 ]

	uploaded=$(find "$FAKE_S3_ROOT/bucket-a/mysql/default" -type f)
	[[ "$uploaded" == *.gpg ]]

	# drop key "one"'s secret key, key "two" alone must still decrypt it
	key_one_fpr=$(gpg --list-secret-keys --with-colons one@example.com | awk -F: '/^fpr:/{print $10; exit}')
	gpg --batch --yes --delete-secret-keys "$key_one_fpr" >/dev/null 2>&1

	decrypted=$(gpg --batch --yes --decrypt "$uploaded" 2>/dev/null)
	[ "$decrypted" = "fake sql dump content" ]
}

@test "942 fails with a clear error when --object is missing" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen
	[ "$status" -eq 1 ]
	[[ "$output" == *"9422"* ]]
}

@test "942 fails with a clear error for an unconfigured --index" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen --object "mysql/default/whatever.gz" --index 9
	[ "$status" -eq 1 ]
	[[ "$output" == *"9423"* ]]
}

@test "942 fails with a clear error when the object doesn't exist on S3" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen --object "mysql/default/does-not-exist.gz" --index 0
	[ "$status" -eq 1 ]
	[[ "$output" == *"9424"* ]]
}

@test "942 downloads a plain backup and hands it to 920 unmodified" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	mkdir -p "$FAKE_S3_ROOT/bucket-a/mysql/default"
	echo "plain backup content" > "$FAKE_S3_ROOT/bucket-a/mysql/default/plain.gz"

	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen --object "mysql/default/plain.gz" --index 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"9421"* ]]
	[[ "$output" == *"STUB920_ARGS:--screen --backupfile"* ]]
	[[ "$output" == *"STUB920_CONTENT:plain backup content"* ]]
}

@test "942 propagates the exit code of 920" {
	write_941_conf '
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
'
	mkdir -p "$FAKE_S3_ROOT/bucket-a/mysql/default"
	echo "plain backup content" > "$FAKE_S3_ROOT/bucket-a/mysql/default/plain.gz"

	export STUB920_EXITCODE=3
	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen --object "mysql/default/plain.gz" --index 0
	[ "$status" -eq 3 ]
}

@test "941 encrypt + 942 restore round-trip: only one of two recipients decrypts it" {
	command -v gpg >/dev/null 2>&1 || skip "gpg not installed"

	export GNUPGHOME="$TEST_HOME/gnupghome"
	mkdir -p -m 700 "$GNUPGHOME"

	for who in one two; do
		cat > "$TEST_HOME/keyparams-$who" <<EOF
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Test $who
Name-Email: $who@example.com
Expire-Date: 1d
%commit
EOF
		gpg --batch --gen-key "$TEST_HOME/keyparams-$who" >/dev/null 2>&1
		gpg --batch --yes --export --armor "$who@example.com" > "$TEST_HOME/pubkey-$who.asc"
	done

	write_941_conf "
S3_ENDPOINT[0]=http://fakes3.test
S3_REGION[0]=us-east-1
S3_BUCKET[0]=bucket-a
S3_PREFIX[0]=mysql
S3_ACCESS_KEY[0]=key
S3_SECRET_KEY[0]=secret
PGP_PUBKEY_FILE[0]=$TEST_HOME/pubkey-one.asc
PGP_PUBKEY_FILE[1]=$TEST_HOME/pubkey-two.asc
"

	run "$TEST_HOME/related-available/941_make_mysql_db_backup_and_transfer_to_s3.sh" --screen --default --encrypt
	[ "$status" -eq 0 ]

	uploaded=$(find "$FAKE_S3_ROOT/bucket-a/mysql/default" -type f)
	objectkey="mysql/default/$(basename "$uploaded")"

	# only key "two" remains available to 942, key "one" is dropped
	key_one_fpr=$(gpg --list-secret-keys --with-colons one@example.com | awk -F: '/^fpr:/{print $10; exit}')
	gpg --batch --yes --delete-secret-keys "$key_one_fpr" >/dev/null 2>&1

	cat >> "$TEST_HOME/config/942.conf" <<EOF
PGP_PASSPHRASE_FILE=
EOF

	run "$TEST_HOME/related-available/942_restore_mysql_db_from_s3.sh" --screen --object "$objectkey" --index 0
	[ "$status" -eq 0 ]
	[[ "$output" == *"STUB920_CONTENT:fake sql dump content"* ]]
}
