import sys, csv

def main(fname):
    idx = fname.rfind(".")
    out_name = "{}_json.txt".format(fname[: idx])
    with open(out_name, 'w') as f_out:
        with open(fname) as f_in:
            reader = csv.reader(f_in)
            header = next(reader)
            for row in reader:
                line = "{"
                for i, val in enumerate(row):
                    if i > 0:
                        line = line + ", "
                    entry = "\"{}\" : \"{}\"".format(header[i], val)
                    line = "{}{}".format(line, entry)
                line = "{}}}\n".format(line)
                f_out.write(line)
                            
if __name__ == "__main__":
    main(sys.argv[1])