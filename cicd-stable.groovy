node('linux')
{
  stage ('Poll') {
                // Poll for local changes
                checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        userRemoteConfigs: [[url: "https://github.com/zopencommunity/libiconvport.git"]]])
  }
  stage('Build') {
    build job: 'Port-Pipeline', parameters: [string(name: 'PORT_GITHUB_REPO', value: 'https://github.com/zopencommunity/libiconvport.git'), string(name: 'PORT_DESCRIPTION', value: 'GNU libiconv provides an implementation of the iconv() function and the iconv program for character set conversion. ' ), string(name: 'BUILD_LINE', value: 'STABLE')]
  }
}
