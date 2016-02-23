import policies.Defaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

freeStyleJob("LnP_Nightly_LoadTest") {
    SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
    SflyDefaults.addRunPermissions(delegate, [ 'klamar' ])
    triggers{
        scm('H 23 * * *')
    }
    label("tp-slave02")    
    steps {
		shell("""/usr/bin/ssh lp-nfs101.lnp.tinyprints.com -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no 'cd /opt/tinyprints/loadTesting/;sudo /opt/tinyprints/loadTesting/runLoadTest.sh 2015_Load_Tests/nightlyLoadTest.jmx'
/usr/bin/scp -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no -o ConnectTimeout=5 lp-nfs101.lnp.tinyprints.com:/opt/tinyprints/loadTesting/logs/nightlyLoadTest*.csv \${WORKSPACE}/
/usr/bin/ssh lp-nfs101.lnp.tinyprints.com -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no -o ConnectTimeout=5 -i -n 'cd /opt/tinyprints/loadTesting/logs/; sudo rm -f nightlyLoadTest*.csv""")
    }

	publishers {
   		SflyDefaults.emailTriggers(delegate, 'klamar@shutterfly.com, jnguyen@shutterfly.com, kshah@shutterfly.com, ngala@shutterfly.com')
    	archiveArtifacts {
        	pattern('/opt/tinyprints/loadTesting/logs/nightlyLoadTest*.csv')
      	}
	}
}
