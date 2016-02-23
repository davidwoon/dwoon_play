import policies.tp.TpDefaults
import policies.sfly.SflyDefaults
import policies.DefaultJobOptions

def jobs = ['nonprod', 'prod']

jobs.each{j->
freeStyleJob("updateDBkeys_$j"){
  SflyDefaults.basic(delegate, [DefaultJobOptions.LOG_ROTATION,DefaultJobOptions.WRAPPERS,DefaultJobOptions.PERMISSIONS])
  def repo = 'build'
  def svn_url
  def shell_c
  def envs
  def item_c

  if (j.find(/nonprod/)){
    svn_url="https://svn03.internal.tinyprints.com/repo/dbPasswords/preproduction/"
    shell_c='perl eng_re/deploy_tp_dbkeyfile "${Env}" "${Project}" "${WORKSPACE}"\nsudo rm -rf keys'
    envs='trunka,trunkm,weeklya,weeklym,lnp,testprod,jenkinsSlaves'
    item_c=7
  }
  else {
    svn_url="https://svn03.internal.tinyprints.com/repo/dbPasswords/production/"
    shell_c='perl eng_re/deploy_tp_dbkeyfile "${Env}" "${Project}" "${WORKSPACE}" "${CCP}"\nsudo rm -rf keys'
    envs='prod,'
    item_c=1
  }

  def build=1
  multiscm {
    git {
      remote {
        url('git@perforce.internal.shutterfly.com:Build')
        credentials('aa689f80-ebbc-4d2c-8c0c-53c7605c18a8')
      }
      branch('*/master')
    }
    svn {
      location('https://svn.tinyprints.com/repo/build/trunk'){
        directory('eng_re')
        credentials('4ce6d486-e836-44a3-a7f9-8203a337ac91')
      }
    }
    svn {
      location("$svn_url"){
        directory("keys")
        credentials('4ce6d486-e836-44a3-a7f9-8203a337ac91')
      }
    }
  }
  label('tp-slave02.internal.tinyprints.com')
  configure {
    it / 'properties' / 'hudson.model.ParametersDefinitionProperty' / 'parameterDefinitions' {
	   'com.cwctravel.hudson.plugins.extended__choice__parameter.ExtendedChoiceParameterDefinition' {
		  delegate.createNode('name','Env')
		  type ('PT_CHECKBOX')
		  quoteValue (false)
		  visibleItemCount (item_c)
		  value (envs)
		  multiSelectDelimiter (',')
	   }
	   'com.cwctravel.hudson.plugins.extended__choice__parameter.ExtendedChoiceParameterDefinition' {
		  delegate.createNode('name','Project')
		  type ('PT_CHECKBOX')
		  quoteValue (false)
		  visibleItemCount ('3')
		  value ('www,platform,token')
		  multiSelectDelimiter (',')
	   }
     if (! j.find(/nonprod/)){
      'hudson.model.StringParameterDefinition'{
        delegate.createNode('name','CCP')
        value('')
      }
     }
    }
  }
  steps {
    shell(shell_c)
  }
  publishers {
    SflyDefaults.emailTriggers(delegate, 'wluo@shutterfly.com')
    //archiveArtifacts {
    //  pattern('**/log*')
    //}
  }
}
}
