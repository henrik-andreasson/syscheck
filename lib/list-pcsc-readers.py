#!/usr/bin/python3

from smartcard.System import readers
# from smartcard.util import toHexString
from smartcard.pcsc.PCSCExceptions import EstablishContextException

try:
    r = readers()

    if len(r) > 0:
        print("Found number of readers:{}".format(len(r)))
        for reader in r:
            print(reader)
    else:
        print("Can not find any attached readers")

except EstablishContextException:
    print("Can not establish contact with PCSC")
