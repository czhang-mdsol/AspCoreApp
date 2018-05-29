#deployment parameters
[Environment]::SetEnvironmentVariable("Application", "MedsExtractorUI")
[Environment]::SetEnvironmentVariable("Environment", "sandbox")
[Environment]::SetEnvironmentVariable("SourcePackageDirectory", "C:\Packages\MedsExtractor")
[Environment]::SetEnvironmentVariable("WorkDirectory", "C:\MedidataApp\unzipped")
[Environment]::SetEnvironmentVariable("DeployPackageLocation", "$env:WorkDirectory\Medidata.MedsExtractor.UI")
[Environment]::SetEnvironmentVariable("ApplicationRootDirectory", "C:\MedidataApp\site")
[Environment]::SetEnvironmentVariable("ApplicationDirectory", "$env:ApplicationRootDirectory\MedsExtractor")
[Environment]::SetEnvironmentVariable("ApplicationProtocol", "http")
[Environment]::SetEnvironmentVariable("ApplicationPortNo", "1390")

#application parameters
[Environment]::SetEnvironmentVariable("ConnectionStrings:MEDbContext", "Data Source=(localdb)\\mssqllocaldb;Initial Catalog=MedsExtractor;Integrated Security=True;")

[Environment]::SetEnvironmentVariable("Environment", "$env:Environment")

[Environment]::SetEnvironmentVariable("MAuth:Uuid", "")
# Note: for local deployments, please converte \n to `n in MAuthPrivateKey
[Environment]::SetEnvironmentVariable("MAuth:PrivateKey", "")
[Environment]::SetEnvironmentVariable("MAuth:ServiceUrl", "https://mauth-sandbox.imedidata.net/")
[Environment]::SetEnvironmentVariable("MAuth:EnabledPaths:0", "/smoke_test")
[Environment]::SetEnvironmentVariable("Zipkin:BaseUri", "https://zipkin-sandbox.imedidata.net/9411/")
[Environment]::SetEnvironmentVariable("Zipkin:EnabledPaths:0", "/smoke_test")
[Environment]::SetEnvironmentVariable("Zipkin:EnabledPaths:1", "/apps")
[Environment]::SetEnvironmentVariable("JobManager:JobManagerRoute", "http://localhost:80/api/v1/jobmanagement")
[Environment]::SetEnvironmentVariable("ApplicationSession:IdleTimeout", "120")