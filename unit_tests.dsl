import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions
import policies.DockerImages

def GITB="${GIT_BRANCH}"
def brh=GITB.replace("origin/", "");
def proj="${JOB_NAME}"
proj=proj.replace("-dsl-seed","").replace("tp-$brh-","")
def run_job = '_unit_tests'
def trigger_job = '_build'
def env
if (brh == 'trunk' || brh == 'weekly'){
  env =  brh +'a'
}
else {
  env = 'testprod'
}
def jobname = env +'_'+proj+run_job
def downstream = env +'_'+proj+ trigger_job

freeStyleJob("$jobname"){
  description("<br/><br/>This job was DSL generated.")   
  SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
  SflyDefaults.buildDescription(delegate, "Revision: \${GIT_COMMIT}<br/>\nBranch: \${GIT_BRANCH}<br/>\nBuild User: <span style=\"font-weight:bold; color:#00F\">\${BUILD_USER}</span><br/>")
  blockOnDownstreamProjects()
  parameters {
    stringParam( 'Environment', env)
        if (env == 'testprod') {
           stringParam( 'tagName',
                       '*/master',
                       "for tagName user tag such as 'refs/tags/v1.0' or branch such as */BUILD-4154 when provided, otherwise default to master branch" )
        }
    }
    if (env == 'testprod'){
         disabled (true)
    }
    
    multiscm
    {
        git{
          remote {
            url("git@gh.internal.shutterfly.com:shutterfly/re-tp-build")
            credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
          }
          branch("*/master")
          relativeTargetDir("eng_re")
        }
        git{
          remote {
            url("GIT_URL")
            credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
          }
          if (env == 'weeklym' || env == 'testprod') {
             branch("\$tagName")
          } else {
             branch("*/$brh")
          }
        }
    }
      
    label("$env")
      
      if (env == 'weeklya' || env == 'weeklym' ) {
        SflyDefaults.dockerImage(delegate, DockerImages.JENKINS_SLAVE_PHP)
      }
      
      steps {
        if (proj == 'www') {
          shell("library/tp/runTests.sh -e $env -x broken,apiTest,manual -d")
        }
        else {
          shell("\${WORKSPACE}/eng_re/template.rb \${WORKSPACE}/tpp/configdata/\$Environment.yaml \${WORKSPACE}/tpp/tpp.config.xml.erb >\${WORKSPACE}/tpp/tpp.config.xml\ntpp/runTests.sh -e $env -x broken,token -c -d")
        }
      }

      triggers {
	    if (env != 'testprod') {
            scm('H/20 * * * *')
	    }
      }

      configure { project ->
        project / publishers << 'com.michelin.cio.hudson.plugins.copytoslave.CopyToMasterNotifier' {
          if (proj == 'www') {
            includes('library/tp/tests/results/')
          }
          else {
            includes('tpp/tests/results/')
          }
          overrideDestinationFolder(false)
        }
        if (proj == 'tokenization' ){
          project / publishers << 'org.jenkinsci.plugins.cloverphp.CloverPHPPublisher' {
            publishHtmlReport(true)
            reportDir('tpp/tests/results/coverage/html/')
            xmlLocation('tpp/tests/results/coverage/coverage.xml')
          }
        }
      }
      publishers {
        if (proj == 'www' ) {
          archiveJunit('library/tp/tests/results/test-results.xml')
        }
        else {
          archiveJunit('tpp/tests/results/test-results.xml')
        }
        SflyDefaults.emailTriggers(delegate, 'engr-re@shutterfly.com')
        downstreamParameterized {
          trigger( downstream, 'SUCCESS', false ) {
            predefinedProp('GitVersion', '$GIT_COMMIT')
            currentBuild()
          }
        }
      }
}
