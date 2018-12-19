import files;
import string;
import sys;
import io;
import stats;
import python;
import math;
import location;
import assert;
import R;

import EQPy;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");

string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");

file model_sh = input(emews_root+"/scripts/cancer-emews.sh");
string exec = argv("model");
string default_xml_config = argv("config");
string num_threads = argv("num_threads");

string tisd = argv("tisd");

string init_population = argv("init_population", "");
string strategy = argv("strategy");
string ga_params = argv("ga_params");
float mut_prob = string2float(argv("mutation_prob", "0.2"));

string to_xml_code =
"""
import params2xml
import json

params = json.loads('%s')
params['parallel.omp_num_threads'] = '%s'
params['user_parameters.random_seed'] = '%s'
params['user_parameters.tumor_immunogenicity_standard_deviation'] = '%s'

#debug
#params['overall.max_time'] = 600

default_config = '%s'
xml_out = '%s'


params2xml.params_to_xml(params, default_config, xml_out)
""";

string result_template =
"""
x <- c(%s)
x <- x[ x >= 0 ]

res <- ifelse(length(x) > 0, mean(x), 9999999999)
""";

string count_template =
"""
import get_metrics

instance_dir = '%s'
# '30240'
count = get_metrics.get_tumor_cell_count(instance_dir, '30240')
""";

app (file out, file err) run(file shfile, string param_file, string instance)
{
    "bash" shfile exec param_file emews_root instance @stdout=out @stderr=err;
}

(string count) parse_tumor_cell_count(string instance) {
  code = count_template % instance;
  count = python_persist(code, "str(count)");
}

(string score) obj(string params, int ga_iter, int param_iter, int trials) {
    string results[];
    // i is used as random seed in input xml
    foreach i in [0:trials-1:1] {
      string instance = "%s/instance_%i_%i_%i/" % (turbine_output, ga_iter, param_iter, i+1);
      make_dir(instance) => {
        xml_out = instance + "config.xml";
        //printf("params: %s", params);
        code = to_xml_code % (params, num_threads, i, tisd, default_xml_config, xml_out);
        file out <instance+"out.txt">;
        file err <instance+"err.txt">;
        python_persist(code, "'ignore'") =>
        (out,err) = run(model_sh, xml_out, instance) =>
        results[i] = parse_tumor_cell_count(instance);
      }
    }

    string result = string_join(results, ",");
    string code = result_template % result;
    score = R(code, "toString(res)");
}

(void v) loop (location ME, int trials) {
    for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    // gets the model parameters from the python algorithm
    string params =  EQPy_get(ME);
    boolean c;
    if (params == "DONE")
    {
        string finals =  EQPy_get(ME);
        // TODO if appropriate
        // split finals string and join with "\\n"
        // e.g. finals is a ";" separated string and we want each
        // element on its own line:
        // multi_line_finals = join(split(finals, ";"), "\\n");
        string fname = "%s/final_result" % (turbine_output);
        file results_file <fname> = write(finals) =>
        printf("Writing final result to %s", fname) =>
        // printf("Results: %s", finals) =>
        v = make_void() =>
        c = false;
    }
    else if (params == "EQPY_ABORT")
    {
        printf("EQPy Aborted");
        string why = EQPy_get(ME);
        // TODO handle the abort if necessary
        // e.g. write intermediate results ...
        printf("%s", why) =>
        v = propagate() =>
        c = false;
    }
    else
    {

        string param_array[] = split(params, ";");
        string results[];
        foreach p, j in param_array
        {
            results[j] = obj(p, i, j, trials);
        }

        string res = join(results, ";");
        //printf("passing %s", res);
        EQPy_put(ME, res) => c = true;

    }
  }
}

(void o) start (int ME_rank, int num_iter, int pop_size, int trials, int seed) {
  location deap_loc = locationFromRank(ME_rank);
  // num_iter, num_pop, seed, strategy, mut_prob, ga_params_file, param_file
  algo_params = "%d,%d,%d,'%s',%f,'%s','%s'" %  (num_iter, pop_size, seed, 
                strategy, mut_prob, ga_params, init_population);
                  
    EQPy_init_package(deap_loc,"deap_ga") =>
    EQPy_get(deap_loc) =>
    EQPy_put(deap_loc, algo_params) =>
      loop(deap_loc, trials) => {
        EQPy_stop(deap_loc);
        o = propagate();
    }
}

// deletes the specified directory
app (void o) rm_dir(string dirname) {
  "rm" "-rf" dirname;
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}

// anything that need to be done prior to a model runs
// (e.g. file creation) can be done here
//app (void o) run_prerequisites() {
//
//}


main() {

  int random_seed = toint(argv("seed", "0"));
  int num_iter = toint(argv("ni","100")); // -ni=100
  int num_variations = toint(argv("nv", "5"));
  int num_pop = toint(argv("np","100")); // -np=100;

  printf("NI: %i # num_iter", num_iter);
  printf("NV: %i # num_variations", num_variations);
  printf("NP: %i # num_pop", num_pop);
  printf("MUTPB: %f # mut_prob", mut_prob);

  // PYTHONPATH needs to be set for python code to be run
  assert(strlen(getenv("PYTHONPATH")) > 0, "Set PYTHONPATH!");
  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  int rank = string2int(r_ranks[0]);
  start(rank, num_iter, num_pop, num_variations, random_seed);
}