#! /bin/bash
install_java () {
  sudo dnf install java-25-openjdk-headless.x86_64 -y 1> /dev/null 2> /dev/null
  if [ $? -ne 0 ]
  then
    echo 'java install failed'
    return 1  
  else 
    echo 'java installed'
  fi
  return 0
}

get_java_version () {
  major_version=$(java -version 2>&1 | head -n 1 | awk '{print $3}' | sed -E 's/"(.*)"/\1/' | awk -F. '{print $1}')
  if [ $? -ne 0 ]
  then
    echo 'could not resolve java version'
    return 1
   fi
   echo $major_version
}
 
java -version 2> /dev/null
if [ $? -ne 0 ]
then
  echo 'installing java'
  result=$(install_java)
  if [ $? -ne 0 ]
  then
    echo $result
    exit 1
  else 
    echo "$result"
  fi
else
  echo 'java installed'
fi
result=$(get_java_version)
if [ $? -ne 0 ]
then
  echo result
  exit 1
fi
java_version=$result
if (( $java_version >=  11 ))
then
  echo "java version $java_version is >= 11"
else
  echo "java version $java_version is < 11"
fi  
