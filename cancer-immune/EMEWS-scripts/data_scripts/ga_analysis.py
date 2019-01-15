import json, sys
import xml.etree.ElementTree as ET
import os, glob

def is_param_set_eq(p1, p2, param_names):
    for p in param_names:
        if p1[p] != p2[p]:
            return False
    return True

def get_final_params(ga_output_path):
    with open("{}/final_result".format(ga_output_path)) as f_in:
        lines = f_in.readlines()
    lines = [x.strip() for x in lines]
    elements = lines[0].split(';')
    params = []
    for e in elements:
        d = json.loads(e)
        # d2 = {}
        # for k,v in d.items():
        #     d2[k.split('.')[1]] = v

        params.append(d)
    return params

def parse_config_xml(instance_path, param_names):
    root = ET.parse("{}/config.xml".format(instance_path))
    
    params = {}
    for p in param_names:
        xpath = p.replace('.', '/')
        el = root.find('./{}'.format(xpath))
        params[p] = float(el.text)
    return params

def parse_metrics(instance_path):
    tumor_cell_count = '-2'
    fname = '{}/output/metrics.txt'.format(instance_path)
    if os.path.exists(fname):
        with open(fname) as f_in:
            tumor_cell_count = '-1'
            line = f_in.readlines()[-1].strip()
            items = line.split("\t")
            if len(items) > 1 and items[0] == '30240':
                tumor_cell_count = items[1]

    return tumor_cell_count


def parse_instances(ga_output_path, param_names, iter_num):
    instances = glob.glob("{}/instance_{}*".format(ga_output_path, iter_num))
    results = []
    for instance in instances:
        tag = os.path.basename(instance)
        params = parse_config_xml(instance, param_names)
        tumor_count = parse_metrics(instance)
        results.append((tag, params, tumor_count))

    return results  
  
def get_unique_params(all_params):
    unique_params = []

    for p in all_params:
        if not p in unique_params:
            unique_params.append(p)
    return unique_params


def main(ga_output_path):
    params = get_final_params(ga_output_path)
    param_names = [x for x in params[0].keys()]
    unique_params = get_unique_params(params)

    stats = []
    for p in unique_params:
        stat = {'params': p, 'instances' : [], 'counts' : []}
        stats.append(stat)

    iter_num = 30
    final_stats = []
    run = True
    while run:
        results = parse_instances(ga_output_path, param_names, iter_num)
        for stat in stats:
            p = stat['params']
            for r in results:
                if r[1] == p:
                    stat['instances'].append(r[0])
                    tc = int(r[2])
                    stat['counts'].append(tc)
                    # if tc in stat['counts']:
                    #     stat['counts'][tc] = stat['counts'][tc] + 1
                    # else:
                    #     stat['counts'][tc] = 1

            if len(stat['instances']) > 0:
                final_stats.append(stat)

        stats = [x for x in filter(lambda s: len(s['instances']) == 0, stats)]
        if len(stats) == 0:
            run = False
        else:
            iter_num = iter_num - 1

    return final_stats
 
    # for s in final_stats:
    #     print(len(s['instances']))

if __name__ == "__main__":
    main(sys.argv[1])
