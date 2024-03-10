#!/usr/bin/env python3
import datetime
from shutil import ExecError
import signal
import subprocess
import sys,os
import time
import argparse

from postProcess import parseInput, printBoard,getBoardMatrix

def doArgs(argList, name):
    parser = argparse.ArgumentParser(description=name)

    parser.add_argument('--timeout', action="store", dest="timeout", type=int, help="max execution time, 0 unlimited", default=0)
    parser.add_argument('--command', action="store", dest="command", type=str, help="CLingo base command", required=True)
    parser.add_argument('--nuke', action="store", dest="nuke_p", type=str, help="kill all processes with this name after the timeout, use wiselly", required=False)
    return parser.parse_args(argList)

# execute a command with a timeout and the parameter par equal to n
def executeWithTimeoutClingo(command, timeout, n, par="t"):
    c = 'timeout -s 15 -k 5 ' + str(timeout) + " " + command + " -c " + par + "=" + str(n)
    output = subprocess.run(c, shell=True, capture_output=True)
    if output.returncode != 10 and output.returncode != 20:
        raise ExecError(output.stderr)
    return output.stdout.decode("utf-8").split("\n")

def getSolutionClingo(output):
    return output[4]

def foundSolClingo(output):
    return output[5] == "SATISFIABLE"

# find and return the optimum wothin the timeout or return none
# if nuke_p is defined it will kill all processes mnamed nuke_p after the timeout
def findMaxPar(command, timeout,nuke_p, par="t"):

    def handler(signum, frame):
        if not nuke_p is None:
            os.system("killall -9 " + nuke_p)
            print("NUKE TIME")
        raise Exception("end of time")

    signal.signal(signal.SIGALRM, handler)
    signal.alarm(timeout)
    n = 1
    t0 = time.time()
    times = []
    while(True):
        try:
            print("Trying " + par + " = " + str(n))
            output = executeWithTimeoutClingo(command,timeout,n,par="t")
            if foundSolClingo(output):
                solution = getSolutionClingo(output)
                print(solution)
                print("\nSolution found with parameter " + par + " = " + str(n))
                finalTime = time.time()
                print(datetime.timedelta(seconds=finalTime-t0))
                signal.alarm(0)
                times.append(finalTime-t0)
                return {par:n,"solution":solution,"time":finalTime-t0,"all_times":times}
            else:
                times.append(time.time()-t0)
                print("Unsatisfiable\n" + output[7]+"\n")
                print("Elapsed time " + str(datetime.timedelta(seconds=time.time()-t0)))
        except TimeoutError as e:
            print("Timeout Exceeded!")
            break
        except ExecError as e:
            print(f'aborting due to error: {e.args[0].decode()}')
            return
        n += 1
    signal.alarm(0)
    return None


def main():
    progName = "Template"
    args = doArgs(sys.argv[1:], progName)

    timeout = args.timeout
    command = args.command
    nuke_p = args.nuke_p
    
    out = findMaxPar(command, timeout,nuke_p, par="t")

    if out is not None:
        moves, positions, n, m = parseInput(out["solution"])
        print(printBoard(getBoardMatrix(positions,n,m)))

    return

if __name__ == '__main__':
    main()