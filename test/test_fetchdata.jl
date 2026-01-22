# Test for default parameters
if !isdir("external")
    datadir = nothing
    settings_file = "GENeSYSMOD.jl/test/TestInputFetch/Set_filter_file.xlsx"
else
    datadir = "external"
    settings_file = "test/TestInputFetch/Set_filter_file.xlsx"
end

@testset "Default Parameters" begin
    @test update_and_process_data(datadir=datadir)
end

# Test for custom result directory
@testset "Custom Result Directory" begin
    resultdir = mktempdir()
    @test update_and_process_data(resultdir=resultdir,datadir=datadir)
    files = readdir(resultdir)
    @test sum([endswith(file,".xlsx") for file in files]) == 2
    @test sum([startswith(file,"RegularParameters") for file in files]) == 1
    @test sum([startswith(file,"Timeseries") for file in files]) == 1
end

# Test for custom settings file directory
@testset "Custom Settings File" begin
    @test update_and_process_data(settings_file = realpath(settings_file), datadir=datadir)
end # realpath makes an absolute path to the file from the relative path

# Test for different processing option
@testset "Different Processing Option" begin
    resultdir = mktempdir()
    @test update_and_process_data(resultdir=resultdir,processing_option="parameters_only",datadir=datadir)
    files = readdir(resultdir)
    @test sum([endswith(file,".xlsx") for file in files]) == 1
    @test sum([startswith(file,"RegularParameters") for file in files]) == 1
    @test sum([startswith(file,"Timeseries") for file in files]) == 0
    resultdir = mktempdir()
    @test update_and_process_data(resultdir=resultdir,processing_option="timeseries_only",datadir=datadir)
    files = readdir(resultdir)
    @test sum([endswith(file,".xlsx") for file in files]) == 1
    @test sum([startswith(file,"RegularParameters") for file in files]) == 0
    @test sum([startswith(file,"Timeseries") for file in files]) == 1
end
