This Ruby program creates multiple threads firing record fetch +
update requests against the ArchivesSpace backend.

The main program is `simulator.rb`, and this launches a fixed number
of threads (defined by `UPDATE_THREADS`), each updating a fixed number
of records (defined by `UPDATES_PER_THREAD`) as quickly as possible.

Each running thread logs timing statistics to a corresponding output
file: one line labelled "SELECT" which indicates how long it took to
retrieve the record from ArchivesSpace, and one lined labelled
"UPDATE" which indicates how long it took to save the record back
again.

To kick the whole thing off, run the following against a TEST instance
of your ArchivesSpace backend:

     cd /path/to/query-simulator
     ./run.sh "http://path.to.my.test.instance:8089/"

The program reads a list of URIs (one per line) from the file
`inputs/records_to_update.txt` in the script's working directory.
These should correspond to the records in ArchivesSpace that will be
fetched and updated during testing.  The URIs provided were randomly
chosen, with a few particularly large records added manually for good
measure.

Output files will be written to `output/updates/[thread id].txt`
within the script's directory.  Lines look like this:

     0	SELECT /repositories/5/archival_objects/129299	328.99999618530273
     1	UPDATE /repositories/5/archival_objects/129299	943.000078201294

Lines are tab-delimited to make it easy to import them into a
spreadsheet.  The first column is the request number, the second
describes the request being made against the backend, and the third is
the number of milliseconds required to complete the request.

**Important note:** These tests are destructive in the sense that they
will trigger real updates against real records in your database, so
don't run them against production.
