node /.*internal$/ {
   	include jenkins
        jenkins::plugin {
                "python" : ;
        }
}
