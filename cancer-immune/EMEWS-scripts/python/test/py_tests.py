import unittest
import xml.etree.ElementTree as ET

import params2xml

class TestParamsToXML(unittest.TestCase):

    def test_params_to_xml(self):
        params = {'user_parameters.tumor_radius' : 'foo:bar:100.32',
                'user_parameters.number_of_immune_cells' : '10',
                'overall.max_time' : '2'}
        xml_file = './test/test_data/PhysiCell.xml'

        xml_out = './test/test_data/xml_out.xml'
        params2xml.params_to_xml(params, xml_file, xml_out)

        root = ET.parse(xml_out)
        tumor_radius = root.findall("./user_parameters/tumor_radius")[0]
        self.assertEqual("foo", tumor_radius.get('type'))
        self.assertEqual("bar", tumor_radius.get('units'))
        self.assertEqual("100.32", tumor_radius.text)

        cells = root.findall("./user_parameters/number_of_immune_cells")[0]
        self.assertEqual("int", cells.get('type'))
        self.assertEqual("dimensionless", cells.get('units'))
        self.assertEqual("10", cells.text)

        max_time = root.findall("./overall/max_time")[0]
        self.assertEqual('2', max_time.text)


if __name__ == '__main__':
    unittest.main()