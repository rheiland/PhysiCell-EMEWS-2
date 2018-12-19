import statistics
import builtins

def min(vals):
    fl = [v for x in vals for v in x if v != 9999999999]
    if len(fl) == 0:
        return -1
    return builtins.min(fl)

def max(vals):
    fl = [v for x in vals for v in x if v != 9999999999]
    if len(fl) == 0:
        return -1
    return builtins.max(fl)

def mean(vals):
    fl = [v for x in vals for v in x if v != 9999999999]
    if len(fl) == 0:
        return -1
    return statistics.mean(fl)

def std(vals):
    fl = [v for x in vals for v in x if v != 9999999999]
    if len(fl) == 0:
        return -1
    return statistics.pstdev(fl)
