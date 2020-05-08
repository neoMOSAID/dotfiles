import sqlite3
import sys
import os
import uuid
import hashlib
import inspect


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def connectDB():
    try:
        path = os.path.dirname(os.path.realpath(__file__)) + "/pplayDB.db"
        con = sqlite3.connect(path)
        return con
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))


def createDB():
    con = connectDB()
    c = con.cursor()
    c.execute(
        """CREATE TABLE IF NOT EXISTS PASSWORDS(
        "id"        INTEGER NOT NULL,
        "user"      TEXT  NOT NULL UNIQUE default "",
        "password"  TEXT  NOT NULL default "",
        PRIMARY KEY ("id")
    );"""
    )
    c.execute(
        """CREATE TABLE IF NOT EXISTS "PLAYLISTS"(
        "id"        INTEGER NOT NULL,
        "name"      TEXT  NOT NULL UNIQUE,
        PRIMARY KEY ("id")
    )"""
    )
    c.execute(
        """CREATE TABLE IF NOT EXISTS "FILES" (
        "id"        INTEGER,
        "file"      TEXT NOT NULL UNIQUE,
        "title"     TEXT,
        "removed"   INTEGER DEFAULT "0",
        PRIMARY KEY ("id")
    ); """
    )
    c.execute(
        """CREATE TABLE IF NOT EXISTS "LISTS" (
        "id"        INTEGER,
        "listid"      INTEGER,
        "fileid"      INTEGER,
        PRIMARY KEY ("id"),
        UNIQUE (listid,fileid) ON CONFLICT IGNORE
    ); """
    )
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS "HISTORY" (
        "id"	INTEGER NOT NULL,
        "name"	text NOT NULL UNIQUE,
        "value"	text NOT NULL,
        PRIMARY KEY("id")
    ); """
    )
    con.commit()
    c.close()
    con.close()


def hash_it(text):
    salt = uuid.uuid4().hex
    s = hashlib.sha256(salt.encode() + text.encode()).hexdigest()
    return s + ":" + salt


def addPass(user, passw):
    try:
        con = connectDB()
        c = con.cursor()
        passw = hash_it(passw)
        c.execute(
            """
                  INSERT OR IGNORE INTO PASSWORDS (user,password)
                  VALUES ("{u}","{p}") """.format(
                u=user, p=passw
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
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
        c.execute(
            """SELECT password FROM PASSWORDS
                  WHERE user = "{user}" """.format(
                user=user
            )
        )
        row = c.fetchone()
        if row:
            r = check_password(row[0], password)
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()
    if pvalue:
        if r:
            print(1)
        else:
            print(0)
    else:
        return r


def getPlayLists():
    try:
        con = connectDB()
        c = con.cursor()
        c.execute("""SELECT * FROM PLAYLISTS""")
        rows = c.fetchall()
        for row in rows:
            print("%s:%s" % (row[0], row[1]))
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getPlayListName(id):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """SELECT name FROM PLAYLISTS
            WHERE id = "{i}" """.format(
                i=id
            )
        )
        row = c.fetchone()
        if row:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def addFile(url):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """INSERT INTO FILES (file)
                VALUES ( "{f}" ) """.format(
                f=url
            )
        )
        con.commit()
        print(c.lastrowid)
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def addList(id, name):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """INSERT INTO PLAYLISTS (id,name)
                VALUES ( "{i}", "{n}" )
                """.format(
                n=name, i=id
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def moveToList(listid, fileid, tolistid):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """REPLACE INTO LISTS (listid,fileid)
                VALUES ( "{t}" , "{f}" )
                WHERE listid = "{l}" AND fileid = "{f}"
                """.format(
                t=tolistid, f=fileid, l=listid
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def addFileToList(listid, fileid):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """INSERT INTO LISTS (listid,fileid)
                VALUES ( "{l}" , "{f}" )
                """.format(
                l=listid, f=fileid
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def deleteFile(file):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """ DELETE FROM FILES
                WHERE file= "{f}" """.format(
                f=file
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def removeFile(action, url):
    if action == "remove":
        removed = 1
    else:
        removed = 0
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """UPDATE FILES
            SET removed = "{r}"
            WHERE file= "{f}" """.format(
                r=removed, f=url
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def addTitle(url, title):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """UPDATE FILES
            SET title = ?
            WHERE file= ? """,
            (url, title),
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getTitles(list):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """SELECT title FROM FILES t1
            INNER JOIN LISTS t2
            ON t1.id = t2.fileid
            WHERE t2.listid = "{l}"
            AND t1.removed = 0
            ORDER BY t2.id ASC """.format(
                l=list
            )
        )
        rows = c.fetchall()
        for row in rows:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getFile(id):
    if id.isdigit():
        query = """SELECT file FROM FILES
                WHERE id = "{}" """.format(
            id
        )
    else:
        query = """SELECT id FROM FILES
                WHERE file = "{}" """.format(
            id
        )
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(query)
        row = c.fetchone()
        if row:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getCount(list):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """SELECT file FROM FILES t1
            INNER JOIN LISTS t2
            ON t1.id = t2.fileid
            WHERE t2.listid = "{l}"
            AND t1.removed = 0
            ORDER BY t2.id ASC """.format(
                l=list
            )
        )
        rows = c.fetchall()
        if rows:
            print(len(rows))
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getAll(list, aa="null"):
    if aa != "null":
        vv = " "
    else:
        vv = "AND  t1.title is null"
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """ SELECT file from FILES t1
                INNER JOIN LISTS t2
                ON t1.id = t2.fileid
                WHERE t2.listid = "{l}"
                 {v}
                AND  t1.file like 'https://%'
                OR t1.file like 'http://%'
            """.format(
                l=list, v=vv
            )
        )
        rows = c.fetchall()
        for row in rows:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def search(list, squery):
    query = """ SELECT file FROM FILES t1
                INNER JOIN LISTS t2
                ON t1.id = t2.fileid
                WHERE t2.listid = "{l}"
                AND t1.removed = 0
                AND {s}
                ORDER BY t2.id ASC
            """.format(
        l=list, s=squery
    )
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(query)
        rows = c.fetchall()
        for row in rows:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def isRemoved(file):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """ SELECT removed FROM FILES
                WHERE file = "{f}"
            """.format(
                f=file
            )
        )
        row = c.fetchone()
        if row:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def getFiles(list, removed=0):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """SELECT file FROM FILES t1
            INNER JOIN LISTS t2
            ON t1.id = t2.fileid
            WHERE t2.listid = "{l}"
            AND t1.removed = "{r}"
            ORDER BY t2.id ASC """.format(
                l=list, r=removed
            )
        )
        rows = c.fetchall()
        for row in rows:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def get(name):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """SELECT value FROM HISTORY
            WHERE name = "{n}" """.format(
                n=name
            )
        )
        row = c.fetchone()
        if row:
            print(row[0])
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def set(name, value):
    try:
        con = connectDB()
        c = con.cursor()
        c.execute(
            """
        INSERT INTO HISTORY (name, value)
        VALUES("{name}", "{value}")
        ON CONFLICT(name) DO UPDATE SET
        name="{name}" , value="{value}"
         """.format(
                name=name, value=value
            )
        )
        con.commit()
        c.close()
    except sqlite3.Error as error:
        eprint("@%s: %s" % (inspect.stack()[0][3], error))
    finally:
        if con:
            con.close()


def myfuncSwitch(arg):
    cmd = arg[1]
    switcher = {
        "create": createDB,
        "addpass": addPass,
        "all": getAll,
        "authenticate": authenticate,
        "getlistname": getPlayListName,
        "getlists": getPlayLists,
        "get": get,
        "set": set,
        "getfile": getFile,
        "getfiles": getFiles,
        "gettitles": getTitles,
        "add": addFile,
        "addtitle": addTitle,
        "addtolist": addFileToList,
        "remove": removeFile,
        "getnfiles": getCount,
        "search": search,
        "addlist": addList,
        "delete": deleteFile,
        "isremoved": isRemoved,
    }
    func = switcher.get(cmd)
    func(*arg[2:])


def main():
    myfuncSwitch(sys.argv)


if __name__ == "__main__":
    main()
