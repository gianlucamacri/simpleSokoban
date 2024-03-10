#!/usr/bin/env python3
import sys
import argparse

def doArgs(argList, name):
    parser = argparse.ArgumentParser(description=name)
    # auxiliary parameters
    parser.add_argument('--input', action="store", dest="inputFn", type=str, help="Input file name", default=None)
    parser.add_argument('--output', action="store", dest="outputFn", type=str, help="Output file name", default=None)
    return parser.parse_args(argList)

def parseInput(s:str):
    s = s.split(" ")
    moves = []
    positions = []

    for el in s:
        if el.startswith("move"):
            el = el[5:-1].split(',')
            moves.append({"box":int(el[0]),
                          "direction":el[1],
                          "time":int(el[2])})
        elif el.startswith("finalPos"):
            el = el[9:-1].split(',')
            positions.append({"box":int(el[0]),
                              "sideLen":int(el[1]),
                              "x":int(el[2]),
                              "y":int(el[3])})
        elif el.startswith("boardX"):
            el = el[7:-1]
            x = int(el)
        elif el.startswith("boardY"):
            el = el[7:-1]
            y = int(el)
        else:
            print("Warning unknown symbol: " + el)

    return moves, positions, x, y

def cleanInput(s:str):
    res = s.split("\n")
    if res[5] != "SATISFIABLE":
        raise Exception("Unsatisfiable")
    return res[4]

# retrive the board matrix from a list of the positions
def getBoardMatrix(positions,n,m):
    board = b = [ [ None for y in range( m ) ]
             for x in range( n ) ]

    for p in positions:
        for i in range(0,p["sideLen"]):
            for j in range(0,p["sideLen"]):
                board[(p["x"]+i-1)][p["y"]+j-1] = p["box"]

    return board

# print 2d ascii representation of the board
def printBoard(board):
    maxYlen = 3

    border = " "*maxYlen +  "+" + "".join(["-" for _ in range(0,len(board)*2-1) ]) + "+"
    s = border + "\n"
    
    for j in range(len(board[0]),0,-1):
        offset = (maxYlen-len(str(j)))*" "
        s +=  str(j) + offset + "|"
        for i in range(0,len(board)):
            el = board[i][j-1]
            if el is None:
                s += " |"
            elif el >= 10: # use some predefined symbols in case of many elements
                s += ["+","*","#","o","a","b","c","d","e","f"][el%10] + "|"
            else:
                s += str(el) + "|"
        s += "\n"
    s += border

    return s


def main():
    progName = "Template"
    args = doArgs(sys.argv[1:], progName)

    inputFn = args.inputFn
    outputFn = args.outputFn

    s = None
    if inputFn == None:
        s = ""
        for line in sys.stdin:
            s += str(line)
    else:
        f = open(inputFn, "r")
        s = f.read()
        f.close()

    try :
        s = cleanInput(s)

        moves, positions, n, m = parseInput(s)

        print(printBoard(getBoardMatrix(positions,n,m)))
    except:
        print("UNSATISFIABLE")

    return


if __name__ == '__main__':
    main()