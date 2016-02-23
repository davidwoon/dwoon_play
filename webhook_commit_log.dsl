import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

freeStyleJob("tp-webhook"){
	SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS]) 
    parameters {
    	stringParam( 'payload', '' )
    }
    authenticationToken('webhooks')
    scm{
      	SflyDefaults.git(delegate, "git@gh.internal.shutterfly.com:shutterfly/re-tp-build.git", "*/master")
    }
    steps {
    	shell("""set +x
echo \$payload > payload_\${BUILD_ID}
perl webhook_ck_commit_log.pl \"payload_\${BUILD_ID}\"
rm payload_\${BUILD_ID}""")
	}
}
