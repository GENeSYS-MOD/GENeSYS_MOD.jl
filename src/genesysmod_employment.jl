# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universität Berlin and DIW Berlin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################

function genesysmod_employment(model,Params,Emp_Sets)
    ######### Reading of Output GDX ##########

#=     if Switch.switch_only_write_results == 1
    ########## Declaration of Output Parameters ##########
    
        parameter excel_production;
        parameter excel_capacity;
        
        $GDXin %gdxdir%Output_%model_region%_%emissionPathway%_%emissionScenario%.gdx
        $load excel_production excel_capacity
    end =#
    
    
    
    if Switch.switch_endogenous_employment == 0
        output_energyjobs = JuMP.Containers.DenseAxisArray(zeros(length(Emp_Sets.Technology),length(Emp_Sets.Year)), Emp_Sets.Technology, Emp_Sets.Year)

        for i ∈ 2:length(Emp_Sets.Year)-1
            for t ∈ Emp_Sets.Technology 
                if Params.EFactorConstruction[t,Emp_Sets.Year[i]] == 0
                    Params.EFactorConstruction[t,Emp_Sets.Year[i]] = (Params.EFactorConstruction[t,Emp_Sets.Year[i-1]]+Params.EFactorConstruction[t,Emp_Sets.Year[i+1]])/2
                end
                if Params.EFactorOM[t,Emp_Sets.Year[i]] == 0
                    Params.EFactorOM[t,Emp_Sets.Year[i]] = (Params.EFactorOM[t,Emp_Sets.Year[i-1]]+Params.EFactorOM[t,Emp_Sets.Year[i+1]])/2
                end
                if Params.EFactorManufacturing[t,Emp_Sets.Year[i]] == 0
                    Params.EFactorManufacturing[t,Emp_Sets.Year[i]] = (Params.EFactorManufacturing[t,Emp_Sets.Year[i-1]]+Params.EFactorManufacturing[t,Emp_Sets.Year[i+1]])/2
                end
                if Params.EFactorFuelSupply[t,Emp_Sets.Year[i]] == 0
                    Params.EFactorFuelSupply[t,Emp_Sets.Year[i]] = (Params.EFactorFuelSupply[t,Emp_Sets.Year[i-1]]+Params.EFactorFuelSupply[t,Emp_Sets.Year[i+1]])/2
                end
                if Params.EFactorCoalJobs[t,Emp_Sets.Year[i]] == 0
                    Params.EFactorCoalJobs[t,Emp_Sets.Year[i]] = (Params.EFactorCoalJobs[t,Emp_Sets.Year[i-1]]+Params.EFactorCoalJobs[t,Emp_Sets.Year[i+1]])/2
                end
                if Params.DeclineRate[t,Emp_Sets.Year[i]] == 0
                    Params.DeclineRate[t,Emp_Sets.Year[i]] = (Params.DeclineRate[t,Emp_Sets.Year[i-1]]+Params.DeclineRate[t,Emp_Sets.Year[i+1]])/2
                end

            end
            for r ∈ Sets.Region_full
                if Params.CoalSupply[r,Emp_Sets.Year[i]] == 0
                    Params.CoalSupply[r,Emp_Sets.Year[i]] = (Params.CoalSupply[r,Emp_Sets.Year[i-1]]+Params.CoalSupply[r,Emp_Sets.Year[i+1]])/2
                end
            end
            if Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",Emp_Sets.Year[i]] == 0
                Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",Emp_Sets.Year[i]] = (Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",Emp_Sets.Year[i-1]]+Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",Emp_Sets.Year[i+1]])/2
            end
            if Params.RegionalAdjustmentFactor[Switch.model_region,Emp_Sets.Year[i]] == 0
                Params.RegionalAdjustmentFactor[Switch.model_region,Emp_Sets.Year[i]] = (Params.RegionalAdjustmentFactor[Switch.model_region,Emp_Sets.Year[i-1]] + Params.RegionalAdjustmentFactor[Switch.model_region,Emp_Sets.Year[i+1]])/2
            end
            if Params.LocalManufacturingFactor[Switch.model_region,Emp_Sets.Year[i]] ==0
                Params.LocalManufacturingFactor[Switch.model_region,Emp_Sets.Year[i]] = (Params.LocalManufacturingFactor[Switch.model_region,Emp_Sets.Year[i-1]] + Params.LocalManufacturingFactor[Switch.model_region,Emp_Sets.Year[i+1]])/2
            end
        end
        
        #ManufacturingJobs(r,c,t,y,'%emissionPathway%_%emissionScenario%') = excel_capacity(r,c,t,y,'NewCapacity','%emissionPathway%_%emissionScenario%')*Params.EFactorManufacturing[t,y]*RegionalAdjustmentFactor('southafrica',y]*LocalManufacturingFactor('southafrica',y]*(1-DeclineRate[t,y])**YearlyDifferenceMultiplier(y);
        #ConstructionJobs(r,c,t,y,'%emissionPathway%_%emissionScenario%') = excel_capacity(r,c,t,y,'NewCapacity','%emissionPathway%_%emissionScenario%')*EFactorConstruction[t,y]*RegionalAdjustmentFactor('southafrica',y]*(1-DeclineRate[t,y])**YearlyDifferenceMultiplier(y);
        #OMJobs(r,c,t,y,'%emissionPathway%_%emissionScenario%') = excel_capacity(r,c,t,y,'TotalCapacity','%emissionPathway%_%emissionScenario%')*EFactorOM[t,y]*RegionalAdjustmentFactor('southafrica',y]*(1-DeclineRate[t,y])**YearlyDifferenceMultiplier(y);
        #SupplyJobs(r,c,t,y,'Production','%emissionPathway%_%emissionScenario%') = sum((f,m,l),excel_production(r,c,t,m,f,y,l,'Production','PJ','%emissionPathway%_%emissionScenario%'))*EFactorFuelSupply[t,y]*RegionalAdjustmentFactor('southafrica',y]*(1-DeclineRate[t,y])**YearlyDifferenceMultiplier(y);
        for t ∈ Emp_Sets.Technology for y ∈ Emp_Sets.Year
            output_energyjobs[Switch.model_region,t,"ManufacturingJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] = sum(output_capacity[Switch.model_region,se,t,"NewCapacity","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*Params.Params.EFactorManufacturing[t,y]*Params.RegionalAdjustmentFactor[Switch.model_region,y]*Params.LocalManufacturingFactor[Switch.model_region,y]*(1-Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets) for se ∈ Sets.Sector)
            output_energyjobs[Switch.model_region,t,"ConstructionJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] =  sum(output_capacity[Switch.model_region,se,t,"NewCapacity","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*Params.EFactorConstruction[t,y]*Params.RegionalAdjustmentFactor[Switch.model_region,y]*(1-Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets) for se ∈ Sets.Sector)
            output_energyjobs[Switch.model_region,t,"OMJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] =  sum(output_capacity[Switch.model_region,se,t,"TotalCapacity","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*Params.EFactorOM[t,y]*Params.RegionalAdjustmentFactor[Switch.model_region,y]*(1-DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets) for se ∈ Sets.Sector)
            output_energyjobs[Switch.model_region,t,"SupplyJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] = (sum(sum(output_energy_balance[Switch.model_region,se,t,m,f,l,"Use","PJ","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] for f ∈ Sets.Fuel for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice)*Params.EFactorFuelSupply[t,y]*(1-Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets) for se ∈ Sets.Sector))*(-1)
        end end
            #EnergyJobs(r,"P_Coal_Hardcoal","SupplyJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] = sum((c),sum((f,m,l),excel_production(r,c,"P_Coal_Hardcoal",m,f,y,l,"Production","PJ","$(Switch.emissionPathway)_$(Switch.emissionScenario)")))*RegionalAdjustmentFactor("southafrica",y]*EFactorCoalJobs("P_Coal_Hardcoal",y];
        for r ∈ Sets.Region_full for y in Emp_Sets.Year
            output_energyjobs[r,"Coal_Heat","SupplyJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] = (sum(sum((output_energy_balance[rr,se,"HLI_Hardcoal",m,"Hardcoal",l,"Use","PJ","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]+output_energy_balance[rr,se,"HMI_HardCoal",m,"Hardcoal",l,"Use","PJ","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]+output_energy_balance[rr,se,"HHI_BF_BOF",m,"Hardcoal",l,"Use","PJ","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]) for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice for se ∈ Sets.Sector ) for rr ∈ Sets.Region_full)*EFactorCoalJobs["Coal_Heat",y]*CoalSupply[r,y])*(-1)
            output_energyjobs[r,"Coal_Export","SupplyJobs","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y] = CoalSupply[r,y]*CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*EFactorCoalJobs["Coal_Export",y]
        end end 

        #TODO :This was comented out in the code from Konstantin, is it needed?
#=     elseif Switch.switch_endogenous_employment == 1
        @variable(model, Jobs_Manufacturing[Sets.Region_full,])
        @variable(model, Jobs_Construction)
        @variable(model, Jobs_OM)
        @variable(model, Jobs_Supply)
        @variable(model, Jobs_Total)

        
        @constraint(model,
        Jobs_Manufacturing == m[:NewCapacity][y,t,r]*Params.EFactorManufacturing[t,y]*Params.RegionalAdjustmentFactor["southafrica",y]*LocalManufacturingFactor["southafrica",y]*(1-DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets),
        base_name="EJ1_ManufacturingJobs_$(r)_$(t)_$(y)")
        
        @constraint(model,
        Jobs_Supply == (UseByTechnology(l,t,f,r)*EFactorFuelSupply[t,y]*(1-DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Emp_Sets)))*(-1)) +
        CoalSupply[r,y]*CoalDigging["southafrica","Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*EFactorCoalJobs["Coal_Export",y],
        base_name= "EJ4_SupplyJobs_$(r)_$(t)_$(y)")
        
        
        @constraint(model,
        Jobs_Total[r,y] ==  Jobs_Manufacturing + Jobs_Construction   + Jobs_OM + Jobs_Supply,
        base_name= "EJX_TotalJobs_$(r)_$(y)]") =#
        
    end

#=     execute_unload "%gdxdir%employment_%model_region%_%emissionPathway%_%emissionScenario%.gdx"
    #OMJobs
    #ConstructionJobs
    #ManufacturingJobs
    #SupplyJobs
    output_energyjobs
    ; =#
    
    
    
    ##########Employment Output Excel Inhalt##########
    
#=     $onecho >%tempdir%temp_%employment_data_file%.tmp
            par=output_energyjobs                       Rng=EnergyJobs!A1     rdim=4        cdim=1
    text="Region"                            Rng=EnergyJobs!A1
    text="Technology"                        Rng=EnergyJobs!B1
    text="JobType"                           Rng=EnergyJobs!C1
    text="Scenario"                          Rng=EnergyJobs!D1
    
    $offecho =#
    
    
    
    
    
#=     if Switch.switch_write_output_excel == 1
        execute 'gdxxrw.exe i=employment.gdx UpdLinks=3 o=%resultdir%Employment_Results_%model_region%_%emissionPathway%_%emissionScenario%.xlsx @%tempdir%temp_%employment_data_file%.tmp';
    end =#
    
end
