import io;
import sys;
import files;
import location;
import string;
import EQR;
import python;
import R;
//import R_obj;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string turbine_output = getenv("TURBINE_OUTPUT");
file model_sh = input(emews_root+"/scripts/cancer-emews.sh");
string exec = argv("model");
string default_xml_config = argv("config");
string num_threads = argv("num_threads");
string tisd = argv("tisd");
float tc_cutoff = tofloat(argv("tc_cutoff", "1.0"));


string r_ranks[] = split(resident_work_ranks,",");
string algorithm = strcat(emews_root,"/R/algo.R");
string param_set = argv("param_set");
int num_clusters        = toint(argv("num_clusters"));
int num_random_sampling = toint(argv("num_random_sampling"));
int max_iter = toint(argv("max_iter", "2"));
int n = toint(argv("n"));
int trials = toint(argv("trials", "20"));
string restart_file = argv("restart_file", "");


string to_xml_code =
"""
import params2xml
import json

params = json.loads('%s')
params['parallel.omp_num_threads'] = '%s'
params['user_parameters.random_seed'] = '%s'
params['user_parameters.tumor_immunogenicity_standard_deviation'] = '%s'

# debug
# params['overall.max_time'] = 600

default_config = '%s'
xml_out = '%s'

params2xml.params_to_xml(params, default_config, xml_out)
""";

string algo_params = """
  data_file = "%s",
  data_cols = 1:6,
  n = %i,
  num_folds = 3,
  max_iter = %i,
  # clustering thresholds
  low_thresh = 0.20,
  high_thresh = 0.80,
  num_cluster_sampling = %i,
  max_clusters = %i,
  num_random_sampling = %i,
  random_sampling_decrease = 0,
  target_metric = "fscore",
  target_metric_value = 100.0,
  ntree = 20,
  restart_file = "%s",
  outdir = "%s"
""" % (param_set, n, max_iter, num_clusters, num_clusters, num_random_sampling,
  restart_file, turbine_output);

string result_template =
"""
x <- c(%s)
x <- x[ x >= 0 ]
tc_cutoff <- (900 * %f)
print(tc_cutoff)
res <- ifelse(length(x) > 0 && mean(x) < tc_cutoff, 'X0', 'X1')
""";

string count_template =
"""
import get_metrics

instance_dir = '%s'
# '30240'
count = get_metrics.get_tumor_cell_count(instance_dir, '30240')
""";


(string count) parse_tumor_cell_count(string instance) {
  code = count_template % instance;
  count = python_persist(code, "str(count)");
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}

app (file out, file err) run(file shfile, string param_file, string instance)
{
    "bash" shfile exec param_file emews_root instance @stdout=out @stderr=err;
}

(string cls) run_model(string params, int iter, int p_num) {

    string results[];
    // i is used as random seed in input xml
    foreach i in [0:trials-1:1] {
      string instance = "%s/instance_%i_%i_%i/" % (turbine_output, iter, p_num, i+1);
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
    string code = result_template % (result, tc_cutoff);
    cls = R(code, "toString(res)");
}

() print_time (string id) "turbine" "0.0" [
  "puts [concat \"@\" <<id>> \" time is: \" [clock milliseconds]]"
];

(void o) al (int r_rank) {
    location loc = locationFromRank(r_rank);
    EQR_init_script(loc, algorithm) =>
    EQR_get(loc) =>
    EQR_put(loc, algo_params) =>
    doAL(loc) => {
        EQR_stop(loc);
        o = propagate();
    }
}

(void v) doAL (location loc) {

    for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    string params =  EQR_get(loc);
    //printf("Iter %i  next params: %s", i, params);
    printf("Iter %i", i);
    boolean c;
    if (params == "FINAL") {
        string final_results =  EQR_get(loc);
        printf("Final results: %s", final_results) =>
        v = make_void() =>
        c = false;
    } else if (params == "EQR_ABORT") {
      printf("EQR aborted: see output for R error") =>
      string why = EQR_get(loc);
      printf("%s", why) =>
      v = propagate() =>
      c = false;
    } else {
      string param_array[] = split(params, ";");
      string results[];
      foreach p, j in param_array
      {
          results[j] = run_model(p, i, j);
      }

      string res = join(results, ";");
      EQR_put(loc, res) => c = true => print_time(fromint(i));
    }
  }
}

printf("WORKFLOW!");

printf("algorithm: %s", algorithm);
al(toint(r_ranks[0]));
