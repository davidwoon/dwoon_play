import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

def environments = ['trunk', 'weekly', 'testprod', 'production']
def run_job = '_workflow_scripts'
def url_map=[
    trunk:"https://svn.tinyprints.com/repo/workflow/branches/trunk-env",
    weekly:"https://svn.tinyprints.com/repo/workflow/branches/weekly-env",
    testprod:"https://svn.tinyprints.com/repo/workflow/branches/testprod",
    production:"https://svn.tinyprints.com/repo/workflow/branches/production"]

environments.each{env->
  def jobname = env+run_job
  def svn_url = url_map."$env"
  freeStyleJob("$jobname"){
    SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
    SflyDefaults.addRunPermissions(delegate, [ 'jchan', 'jluu', 'jpalileo', 'jshrestha', 'kazhar', 'rng' ])

    if (env == 'production'){
      parameters {
        stringParam( 'CCP','')
      }
    }
    label('ws01')
		def dir
		if (env == 'trunk'){
		    dir = 'trunk-env'
		} else if ( env == 'weekly'){
		    dir = 'weekly-env'
		} else {
		    dir = env
    }
    
    multiscm {
      git {
        remote {
          url('git@perforce.internal.shutterfly.com:Build')
          credentials('aa689f80-ebbc-4d2c-8c0c-53c7605c18a8')
        }
        branch('*/master')
      }
      git{
          remote {
            url("git@gh.internal.shutterfly.com:shutterfly/re-tp-workflow")
            credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
          }
          branch("*/master")
          relativeTargetDir("workflow")
        }
      svn {
        location("$svn_url"){
          directory("$dir")
          credentials('4ce6d486-e836-44a3-a7f9-8203a337ac91')
        }
      }
    }
    
    triggers {
      if (env != 'production'){
        scm ('H/30 * * * *')
      }
    }
    wrappers {
      timeout {
        absolute(20)
        failBuild()
        writeDescription('Build failed due to timeout after {0} minutes')
      }
    }
    steps {
      if (env == 'trunk') {
        shell('sudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=trunka\nsudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=trunkm')
      }
      else if (env == 'weekly') {
        shell('sudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=weeklya\nsudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=weeklym')
      }
      else if (env == 'testprod') {
        shell('sudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=testprod')
      }
      else if (env == 'production') {
        shell('/usr/bin/perl requireCCP ${CCP}\nsudo phing -f ${WORKSPACE}/workflow/build.xml -Denvironment=production')
      }
		}
		publishers {
      SflyDefaults.emailTriggers(delegate, 'wluo@shutterfly.com')
    }
   }
}
