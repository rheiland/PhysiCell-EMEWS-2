import statistics
import builtins

def min(vals):
    fl = [v for x in vals for v in x]
    return builtins.min(fl)

def max(vals):
    fl = [v for x in vals for v in x]
    return builtins.max(fl)

def mean(vals):
    fl = [v for x in vals for v in x]
    return statistics.mean(fl)

def std(vals):
    fl = [v for x in vals for v in x]
    return statistics.pstdev(fl)
