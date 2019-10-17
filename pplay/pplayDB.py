import sqlite3
import sys
import os
import uuid
import hashlib
import inspect
import base64


def eprint(*args,  **kwargs):
    print(*args,  file=sys.stderr,  **kwargs)


def connectDB():
    try:
        path = os.path.dirname(os.path.realpath(__file__)) + "/pplayDB.db"
        con = sqlite3.connect(path)
        return con
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3],  error))


def createDB():
    con = connectDB()
    c = con.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS PASSWORDS(
        user text  NOT NULL UNIQUE default "",
        password text  NOT NULL default ""
    );""")
    c.execute("""CREATE TABLE IF NOT EXISTS "PLAYLISTS"(
        "id"        INTEGER NOT NULL,
        "name"      TEXT  NOT NULL UNIQUE,
        PRIMARY KEY ("id")
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS "FILESLIST" (
        "id"        INTEGER,
        "list"      INTEGER NOT NULL,
        "removed"   INTEGER DEFAULT "0",
        "file"      TEXT,
        PRIMARY KEY ("id"),
        UNIQUE (list,file) ON CONFLICT IGNORE
    ); """)
    c.execute("""CREATE TABLE IF NOT EXISTS "INDEXES" (
        "list" INTEGER PRIMARY KEY,
        "index" INTEGER DEFAULT 1
    ); """)
    c.execute("""CREATE TABLE IF NOT EXISTS "TITLES" (
        "id" INTEGER PRIMARY KEY,
        "title" TEXT
    ); """)
    c.execute("""CREATE TABLE IF NOT EXISTS "tmp_table" (
        "id" INTEGER  PRIMARY KEY,
        "fid" INTEGER NOT NULL UNIQUE
    ); """)
    con.commit()
    c.close()
    con.close()


def encode(data):
    urlSafeEncodedBytes = base64.urlsafe_b64encode(data.encode("utf-8"))
    urlSafeEncodedStr = str(urlSafeEncodedBytes, "utf-8")
    return urlSafeEncodedStr


def decode(data):
    decodedBytes = base64.urlsafe_b64decode(data)
    decodedStr = str(decodedBytes, "utf-8")
    return decodedStr


def hash_it(text):
    salt = uuid.uuid4().hex
    s = hashlib.sha256(salt.encode() + text.encode()).hexdigest()
    return s + ":" + salt


def addPass(user, passw):
    try:
        con = connectDB()
        c = con.cursor()
        passw = hash_it(passw)
        c.execute("""
                  INSERT OR IGNORE INTO PASSWORDS (user,password)
                  VALUES ("{u}","{p}") """ .format(u=user, p=passw))
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if (con):
            con.close()


def check_password(hashed_password, user_password):
    password, salt = hashed_password.split(":")
    upass = hashlib.sha256(salt.encode() + user_password.encode()).hexdigest()
    return password == upass


def authenticate(user, password, pvalue=0):
    r = 0
    try:
        con = connectDB()
        c = con.cursor()
        c.execute("""SELECT password FROM PASSWORDS
                  WHERE user = "{user}" """.format(user=user))
        row = c.fetchone()
        if (row):
            r = check_password(row[0], password)
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if (con):
            con.close()
    if(pvalue):
        if(r):
            print(1)
        else:
            print(0)
    else:
        return r


def getList(l):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute("""SELECT file FROM FILESLIST
            WHERE list = "{ll}" AND removed != 1 """.format(ll=l))
        rows = c.fetchall()
        for row in rows:
            print(decode(row[0]))
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if (con):
            con.close()


def myfuncSwitch(arg):
    cmd = arg[1]
    switcher = {
        "create": createDB,
        "addpass": addPass,
        "authenticate": authenticate,
        "getl": getList
    }
    func = switcher.get(cmd)
    func(*arg[2:])


def main():
    myfuncSwitch(sys.argv)


if __name__ == "__main__":
    main()
