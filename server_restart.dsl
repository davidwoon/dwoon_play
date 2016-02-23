import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

def env = TpDefaults.getEnvs()

freeStyleJob("Server_Restart"){
  SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
  parameters {
    choiceParam( 'Env',
                env,
                'Environment pools to be restarted' )
  }
  scm {
    git{
      remote {
        url("git@gh.internal.shutterfly.com:shutterfly/re-tp-build")
        credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
      }
      branch("*/master")
      relativeTargetDir("eng_re")
    }
  }
  label('prod')
  steps {
    shell('rm -rf $WORKSPACE/log*_*\nchmod +x ./eng_re/server_restart\n./eng_re/server_restart')
  }
} 
