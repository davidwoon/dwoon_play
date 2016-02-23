import policies.DefaultJobOptions
import policies.sfly.SflyDefaults
import policies.tp.TpDefaults
import policies.Defaults

def environments = TpDefaults.getEnvs() 
def projects = ['creative'] 
def pool_map = [trunka:"ta-www", trunkm:"tm-www", weeklya:"group-wa-creative", weeklym:"group-wm-creative", testprod:"group-tp1-lv-creative", lnp:"lp-www", ftm:"group-ftm-creative", shk:"group-shk-creative", tpe:"group-tpe-creative", prod:"group-creativepush"]

environments.each{env->
    projects.each{proj->
        def jobname = proj+'_'+env
        def wwwjob = env+'_www_deploy'
        freeStyleJob("$jobname") {
            SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
            SflyDefaults.addRunPermissions(delegate, [ 'bquon', 'dchung', 'cseto', 'jlau', 'kpearsall', 'djimenez', 'DCO'])
            description('use creative_prod for singlehost push')
            label("creative")
            blockOn(wwwjob)
            def svn_url
            def dir="sites"
            def view_url
            if (env.find(/testprod/)){
                svn_url = 'https://svn03.internal.tinyprints.com/repo/MarketingAssets/release/sites'
                view_url = 'https://svn03.internal.tinyprints.com/websvn/wsvn/MarketingAssets/release/sites'
	       }
	       else {
                svn_url = 'https://svn03.internal.tinyprints.com/repo/MarketingAssets/trunk/sites'
                vivew_dir = 'https://svn03.internal.tinyprints.com/websvn/wsvn/MarketingAssets/trunk/sites'
	       }
           if (env == "prod"){
            svn_url = 'https://svn03.internal.tinyprints.com/repo/MarketingAssets/release/sites@${SUBVERSION_REVISION}'
            parameters {
                stringParam( 'CCP',
                    '',
                    "Approved CCP for this production deploy" )
                stringParam( "SUBVERSION_REVISION",
                    'HEAD',
                    "Default to HEAD, use specific revision to push to environments.\neg. 1126" )
                booleanParam( "SingleHost",
                    true)
            }
            configure { project ->
                Defaults.ircPublisher( delegate, project, cName )
            }
            }
            multiscm {
            if (env == "prod"){
            git {
                remote {
                    url('git@perforce.internal.shutterfly.com:Build')
                    credentials('aa689f80-ebbc-4d2c-8c0c-53c7605c18a8')
                }
                branch('*/master')
            }
            }
            git{
                remote {
                    url("git@gh.internal.shutterfly.com:shutterfly/re-tp-build")
                    credentials('cfd4f4f5-dceb-4ff9-a17e-0cb31a6432b6')
                }
                branch("*/master")
                relativeTargetDir("eng_re")
            }
            svn {
                location("$svn_url"){
                    directory("$dir")
                    credentials('4ce6d486-e836-44a3-a7f9-8203a337ac91')
                }
            }
           }
	       triggers {
	    	switch ( env ) {
                   case "testprod":
                        scm('0 18 * * *\n0 16 * * 5')
                        break
                   case "trunka":
                        scm('40 */2 * * *')
                        break
                   case "trunkm":
                        scm('30 */2 * * *')
                        break
                   case "weeklya":
                        scm('20 */2 * * *')
                        break
                   case "weeklym":
                        scm('00 */2 * * *')
                        break
                   case "lnp":
                        scm('0 1 * * *')
                        break
                }
	       }
            steps {
                shell('rm -rf $WORKSPACE/log*_*\nif [[ \"$env\" == \"prod\" ]]; then\n/usr/bin/perl Build/requireCCP \${CCP}\nfi\nif [[ \$SingleHost == true ]]; then\nPool=www201\nelse\nPool='+pool_map."$env" + '\nfi\n./eng_re/creative_deployment -s '+svn_url+'@head -p ${Pool} -d -j -v ${SVN_REVISION_1}')
                }
            publishers {
                SflyDefaults.emailTriggers(delegate, 'engr-re@shutterfly.com creativeweb_tp@shutterfly.com')
                archiveArtifacts {
                    pattern('**/log*')
                }
            }
        }
    }
}
