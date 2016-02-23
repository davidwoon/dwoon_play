import policies.Defaults
import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

def env = 'prod' 
def projects = TpDefaults.getProjects()
def run_job = 'switch'
projects.add('web2print')

projects.each{proj->
   def jobname = env+'_'+proj+'_'+run_job
   if ( proj == 'web2print') {
       jobname = env+'_'+proj+'_deploy_and_switch'
   }
   def creative = 'creative_prod'
   freeStyleJob("$jobname"){
     SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
     parameters {
        stringParam( 'Project',
                    proj )
        stringParam( 'Version',
                    ''   )
        stringParam( 'Env',
                    env  )
        booleanParam("Restart",
	       	    false)
        stringParam( 'CCP',
	   	    '' )
      }
      if ( proj == 'www' ){
        blockOn(creative)
      }
      
      multiscm {
        git{
          remote {
            url("git@gh.internal.shutterfly.com:shutterfly/re-tp-build")
            credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
          }
          branch("*/master")
          relativeTargetDir("eng_re")
        }
        git {
          remote {
            url('git@perforce.internal.shutterfly.com:Build')
            credentials('aa689f80-ebbc-4d2c-8c0c-53c7605c18a8')
          }
          branch('*/master')
          //relativeTargetDir('Build')
        }
      }
      if (env == 'prod' && proj == 'tokenization' ) {
        label("prod-token")
      } else {
        label('prod')
      }
      configure { project ->
        TpDefaults.setBuildDescription ( delegate, project )
        Defaults.ircPublisher( delegate, project, "#tp" )
      }
    if ( proj == 'web2print' ) {
        steps {
            shell('rm -rf $WORKSPACE/log*_*\n${WORKSPACE}/Build/deployw2p -s tp -e ${Env} -r ${Version}')
        }
    }
    else {
        steps {
            shell('rm -rf $WORKSPACE/log*_*\n./eng_re/switch_tp -e ${Env}')
        }
    } 
    publishers {
      SflyDefaults.emailTriggers(delegate, 'engr-re@shutterfly.com')
      archiveArtifacts {
        pattern('**/log*')
      }
    }
  }
}
