from explorer.exporters import CSVExporter
from six import BytesIO


class CSVExporterBOM(CSVExporter):
    def _get_output(self, res, **kwargs):
        csv_data = super(CSVExporterBOM, self)._get_output(res, **kwargs)
        csv_data_io = BytesIO()
        csv_data_io.write(b'\xef\xbb\xbf')
        csv_data_io.write(csv_data.getvalue().encode('utf-8'))
        return csv_data_io
