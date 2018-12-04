import io;
import sys;
import files;
import python;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string exec = argv("model");
string default_xml_config = argv("config");
string num_threads = argv("num_threads");

to_xml_code =
"""
import params2xml
import json

params = json.loads('%s')
params['parallel.omp_num_threads'] = '%s'
default_config = '%s'
xml_out = '%s'

params2xml.params_to_xml(params, default_config, xml_out)
""";

app (file out, file err) run_model (file shfile, string param_file, string instance)
{
    "bash" shfile exec param_file emews_root instance @stdout=out @stderr=err;
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}


file model_sh = input(emews_root+"/scripts/cancer-emews.sh");
file json_input = input(argv("f"));
string lines[] = file_lines(json_input);
foreach s,i in lines {
  string instance = "%s/instance_%i/" % (turbine_output, i+1);
  make_dir(instance) => {
    xml_out = instance + "config.xml";
    code = to_xml_code % (s, num_threads, default_xml_config, xml_out);
    file out <instance+"out.txt">;
    file err <instance+"err.txt">;
    python_persist(code, "'ignore'") =>
    (out,err) = run_model(model_sh, xml_out, instance);
  }
}

