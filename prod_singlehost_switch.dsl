import policies.sfly.SflyDefaults
import policies.tp.TpDefaults
import policies.DefaultJobOptions


def jobname = 'prod_singlehost_switch'
freeStyleJob("$jobname")
{
    SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
    description('Switch single hosts for WWW and Platform as\n\nWWWSERVER="www201.internal.tinyprints.com"\nAPISERVER="api201.internal.tinyprints.com"')
    parameters {
        stringParam( 'WWW_VERSION',
                     '',
                     'WWW version to switch.')
        stringParam( 'PLATFORM_VERSION',
                     '',
                     'Platform version to switch.')
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
    label( 'prod' )
    steps {
        shell('chmod 777 eng_re/single_server_switch\n./eng_re/single_server_switch ${WWW_VERSION} ${PLATFORM_VERSION}')
    }
    publishers {
        SflyDefaults.emailTriggers(delegate, 'wluo@shutterfly.com')
    }
}
