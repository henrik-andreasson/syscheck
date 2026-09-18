# Checking database consistency across nodes

`sc_32_check_db_sync.sh` compares a set of tables across two or three database
nodes and reports whether they hold the same data.

## The problem: the database moves while you look at it

The obvious implementation — run `CHECKSUM TABLE` on every node and compare —
does not work on a live system. Between the moment node1 answers and the moment
node2 answers, the application has committed more transactions. The two
checksums disagree, and the check reports a divergence that does not exist.

On a busy table this is not an edge case, it is the normal outcome. A check
that cries wolf every run is worse than no check at all, because operators stop
reading it.

Three things have to be dealt with:

1. **Writes in flight.** Rows are being inserted while the comparison runs.
2. **Replication lag.** A node can be seconds behind and still perfectly
   healthy. Being behind is not the same as being wrong.
3. **Row order.** Nodes may store or return rows in different physical order,
   so the comparison must not depend on ordering.

## The approach

### 1. Only compare rows that can no longer change

For each table, configure a **cutoff column** — a timestamp set when the row is
written. The comparison then covers only rows older than a settle window:

```sql
WHERE <cutoff column> <= NOW() - INTERVAL <settle seconds> SECOND
```

Anything written inside the settle window is excluded on every node, so
in-flight writes cannot affect the result. Set the settle window comfortably
above your worst normal replication lag; 60 seconds is a sensible default.

This is the part that makes the check deterministic on a moving database. It
assumes rows are not modified after they are written, or that updates also bump
the cutoff column. For EJBCA's `CertificateData` and `CRLData` that holds.

For small reference tables that are written rarely, leave the cutoff column
empty and the whole table is compared instead.

### 2. Treat a first mismatch as a suspicion, not a verdict

Even inside the settle window a node can be behind. So a mismatch is never
reported immediately: the check waits and recomputes, up to a configured number
of attempts.

- If the nodes converge, the difference was **replication lag** — reported as a
  WARNING, with the number of attempts it took.
- If they still disagree after the last attempt, the difference is **real** —
  reported as an ERROR.

This is what separates "node2 is 3 seconds behind" from "node2 is missing 400
rows", without needing to read replication status at all. It also means the
check degrades gracefully on a cluster under load rather than going red.

### 3. Compare a checksum that does not depend on row order

Per table and node:

```sql
SELECT COUNT(*),
       COALESCE(BIT_XOR(CRC32(CONCAT_WS('#', IFNULL(c1,'~N~'), IFNULL(c2,'~N~'), ...))), 0)
FROM <db>.<table>
WHERE <cutoff> <= NOW() - INTERVAL <settle> SECOND
```

- `BIT_XOR` is commutative, so physical row order is irrelevant.
- `CRC32` over the concatenated row detects content differences, not just row
  counts.
- `IFNULL(...,'~N~')` stops `NULL` and the empty string hashing identically,
  which plain `CONCAT_WS` would do because it skips NULLs.
- `COUNT(*)` is compared as well as the checksum. It is the cheaper signal, and
  it catches the one case `BIT_XOR` alone can miss: XOR cancels identical
  values, so a table containing two extra *identical* rows would have an
  unchanged checksum. The row count catches that.

The column list is read from `information_schema.COLUMNS` at runtime, so no
schema is hard-coded and a column added later is picked up automatically.

## What it does not do

This is a monitoring check, not a repair tool, and not a substitute for
`pt-table-checksum`.

- It does not read replication coordinates or GTIDs. It infers "behind" from
  convergence on retry. That is less precise but needs no replication
  privileges and behaves the same on Galera as on classic replication.
- It does not tell you *which rows* differ. When it reports a divergence, use
  `pt-table-checksum` / `pt-table-sync`.
- `BIT_XOR` over CRC32 is a monitoring-grade checksum, not a cryptographic one.
  It will not detect a deliberately crafted collision.

## Configuration

See `config/32.conf`. Nodes default to `HOSTNAME_NODE1` and `HOSTNAME_NODE2`
from `common.conf`; add a third entry to `DBSYNC_NODE[]` for a three-node
cluster. Database credentials come from `config/mariadb.conf`.

```
DBSYNC_NODE[0]=192.168.158.151
DBSYNC_NODE[1]=192.168.158.171

DBSYNC_SETTLE_SECONDS=60
DBSYNC_RECHECK_TRIES=3
DBSYNC_RECHECK_DELAY=5

SYNCTABLE[0]=CertificateData
SYNCCUTOFF[0]=updateTime

SYNCTABLE[1]=CRLData
SYNCCUTOFF[1]=thisUpdate

SYNCTABLE[2]=CAData
SYNCCUTOFF[2]=
```

Each table is reported separately with its own script index, followed by a
summary message.

## Error codes

| Code | Level | Meaning |
| --- | --- | --- |
| 321 | INFO | Table is identical on all nodes |
| 322 | ERROR | Table still differs after the last retry |
| 323 | WARNING | Table differed but converged — replication lag |
| 324 | ERROR | A node could not be queried |
| 325 | ERROR | Table missing on a node |
| 326 | ERROR | Configuration problem |
| 327 | INFO | Summary: all tables in sync |
| 328 | ERROR | Summary: at least one table out of sync |
