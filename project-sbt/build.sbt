organization := "org.llvm.openmp"

name := "ompcloud-dep"

version := "0.2.0-SNAPSHOT"

scalaVersion := "2.11.8"

libraryDependencies += "com.amazonaws" % "aws-java-sdk" %   "1.7.4"
libraryDependencies += "org.apache.hadoop" % "hadoop-aws" % "2.7.3" excludeAll(
    ExclusionRule("com.amazonaws", "aws-java-sdk"),
    ExclusionRule("commons-beanutils")
)

libraryDependencies += "org.apache.spark" %% "spark-core" % "2.0.0" % "provided"
libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.0.0" % "provided"
