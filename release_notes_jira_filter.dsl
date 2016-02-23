import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions
import policies.DockerImages

def environments = TpDefaults.getEnvs() 
def projects = ['www'] 
def run_job = 'platform_api_tests'
environments.remove('prod')
environments.remove('workflow')
environments.each{env->
    projects.each{proj->
        def jobname = 'jira_filter_for_release_notes'
        freeStyleJob("$jobname"){
          SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS]) 
          description('This job only runs in www pipeline')
          blockOnDownstreamProjects()
          blockOnUpstreamProjects()
          def branch
          label("$env")
          if ( env.find(/trunk/)){
            branch='*/trunk'
          }
          else if (env.find(/weekly/)){
            branch='*/weekly'
            }
	        else if (env.find(/lnp/)){
	           branch='*/weekly'
	        }
	         else if (env.find(/testprod/)){
		          branch='*/master'
	        }
           if (env == 'weeklya' || env == 'weeklym' ) {
              SflyDefaults.dockerImage(delegate, DockerImages.JENKINS_SLAVE_PHP)
           }
	       scm {
	           SflyDefaults.git(delegate, "git@gh.internal.shutterfly.com:shutterfly/tp-www.git", "$branch")
           }
           configure { project ->
            TpDefaults.setBuildDescription ( delegate, project )
            }
            steps {
                shell('$WORKSPACE/library/tp/runTests.sh -e ${Env} -g apiTest -x broken,manual,CacheValidation -c -d')
            }
        publishers {
                archiveJunit('library/tp/tests/results/test-results.xml')
                SflyDefaults.emailTriggers(delegate, 'engr-re@shutterfly.com')
            }
        }
    }  
}
