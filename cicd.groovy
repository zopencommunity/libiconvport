node('linux')
{
  stage('Build') {
    build job: 'Port-Pipeline', parameters: [string(name: 'PORT_GITHUB_REPO', value: 'https://github.com/ZOSOpenTools/libiconvport.git'), string(name: 'PORT_DESCRIPTION', value: 'GNU libiconv provides an implementation of the iconv() function and the iconv program for character set conversion. ' )]
  }
}
