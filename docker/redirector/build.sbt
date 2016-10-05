name := "redirect-war"

version := "1.0"

scalaVersion := "2.11.8"

libraryDependencies := {
  lazy val specs2Version = "3.8.5"

  Seq(
    "javax.servlet" % "javax.servlet-api" % "3.0.1" % Provided,
    "org.scala-lang" % "scala-library" % "2.11.8" % Provided,
    "org.specs2" %% "specs2-core" % specs2Version % Test,
    "org.specs2" %% "specs2-mock" % specs2Version % Test
  )
}

scalacOptions in Test ++= Seq("-Yrangepos")

val app = (project in file("."))
  .enablePlugins(WarPlugin)

webappPostProcess := {
  webappDir: File ⇒
    def listFiles(level: Int)(f: File): Unit = {
      val indent = ((1 until level) map { _ ⇒ "  " }).mkString
      if (f.isDirectory) {
        streams.value.log.info(indent + f.getName + "/")
        f.listFiles foreach { listFiles(level + 1) }
      } else streams.value.log.info(indent + f.getName)
    }
    listFiles(1)(webappDir)
}
