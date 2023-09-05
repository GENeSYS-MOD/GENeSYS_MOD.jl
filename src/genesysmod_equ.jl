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
# Unless required by applicable law || agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express || implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################

function genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch)

  dbr = Switch.data_base_region
   ######################
   # Objective Function #
   ######################
  start=Dates.now()
  @variable(model,z)
  @variable(model, RegionalBaseYearProduction_neg[Sets.Year,Sets.Region_full,Sets.Technology,Sets.Fuel])
  for y ∈ Sets.Year for r ∈ Sets.Region_full for t ∈ Sets.Technology for f ∈ Sets.Fuel
    JuMP.fix(model[:RegionalBaseYearProduction_neg][y,r,t,f], 0;force=true)
  end end end end

#=   @constraint(model, cost, model[:z] == sum(model[:TotalDiscountedCost][y,r] for y ∈ Sets.Year for r ∈ Sets.Region_full)
  + sum(model[:DiscountedAnnualTotalTradeCosts][y,r] for y ∈ Sets.Year for r ∈ Sets.Region_full)
  + sum(model[:DiscountedNewTradeCapacityCosts][y,f,r,rr] for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full for rr ∈ Sets.Region_full)
  + sum(model[:DiscountedAnnualCurtailmentCost][y,f,r] for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full)
  + sum(model[:RegionalBaseYearProduction_neg][y,r,t,f]*9999 for y ∈ Sets.Year for r ∈ Sets.Region_full for f ∈ Sets.Fuel for t ∈ Sets.Technology)
  + sum(model[:BaseYearOvershoot][r,t,f,y]*999 for y ∈ Sets.Year for r ∈ Sets.Region_full for f ∈ Sets.Fuel for t ∈ Sets.Technology))
 =#
  @constraint(model, cost, model[:z] == sum(model[:TotalDiscountedCost][y,r] for y ∈ Sets.Year for r ∈ Sets.Region_full)
  + sum(model[:DiscountedAnnualTotalTradeCosts][y,r] for y ∈ Sets.Year for r ∈ Sets.Region_full)
  + sum(model[:DiscountedNewTradeCapacityCosts][y,f,r,rr] for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full for rr ∈ Sets.Region_full)
  + sum(model[:DiscountedAnnualCurtailmentCost][y,f,r] for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full)
  + sum(model[:BaseYearOvershoot][r,t,"Power",y]*999 for y ∈ Sets.Year for r ∈ Sets.Region_full for t ∈ Sets.Technology))
  @objective(model, MOI.MIN_SENSE, model[:z])
  print("Cstr: Cost : ",Dates.now()-start,"\n")
  

   #########################
   # Parameter assignments #
   #########################

  start=Dates.now()
  for y ∈ Sets.Year for l ∈ Sets.Timeslice for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    Params.RateOfDemand[y,l,f,r] = Params.SpecifiedAnnualDemand[r,f,y]*Params.SpecifiedDemandProfile[r,f,l,y] / Params.YearSplit[l,y]
    Params.Demand[y,l,f,r] = Params.RateOfDemand[y,l,f,r] * Params.YearSplit[l,y]
    if Params.Demand[y,l,f,r] < 0.000001
      Params.Demand[y,l,f,r] = 0
    end
  end end end end
  print("RateOfDemand : ",Dates.now()-start,"\n")

  start=Dates.now()

  LoopSetOutput = Dict()
  LoopSetInput = Dict()
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    LoopSetOutput[(r,f,y)] = [(x[1],x[2]) for x in keys(Params.OutputActivityRatio[r,:,f,:,y]) if Params.OutputActivityRatio[r,x[1],f,x[2],y] > 0]
    LoopSetInput[(r,f,y)] = [(x[1],x[2]) for x in keys(Params.InputActivityRatio[r,:,f,:,y]) if Params.InputActivityRatio[r,x[1],f,x[2],y] > 0]
  end end end

  function CanFuelBeUsedByModeByTech(y, f, r,t,m)
    temp = Params.InputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y]
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  function CanFuelBeUsedByTech(y, f, r,t)
    temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation )
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  function CanFuelBeUsed(y, f, r)
    temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  function CanFuelBeUsedInTimeslice(y, l, f, r)
    temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    Params.CapacityFactor[r,t,l,y] *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  CanFuelBeUsedOrDemanded = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full)
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    temp = (isempty(LoopSetInput[(r,f,y)]) ? 0 : sum(Params.InputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for (t,m) ∈ LoopSetInput[(r,f,y)]))
    if (!ismissing(temp)) && (temp > 0) || Params.SpecifiedAnnualDemand[r,f,y] > 0
      CanFuelBeUsedOrDemanded[y,f,r] = 1
    end
  end end end 

  function CanFuelBeProducedByModeByTech(y, f, r,t,m)
    temp = Params.OutputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y]
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  function CanFuelBeProducedByTech(y, f, r,t)
    temp = sum(Params.OutputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation)
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end


  CanFuelBeProduced = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full)
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    temp = (isempty(LoopSetOutput[(r,f,y)]) ? 0 : sum(Params.OutputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for (t,m) ∈ LoopSetOutput[(r,f,y)]))
    if (temp > 0)
      CanFuelBeProduced[y,f,r] = 1
    end
  end end end

  function CanFuelBeProducedInTimeslice(y, l, f, r)
    temp = sum(Params.OutputActivityRatio[r,t,f,m,y]*
    Params.TotalAnnualMaxCapacity[r,t,y] * 
    Params.CapacityFactor[r,t,l,y] *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
    if (!ismissing(temp)) && (temp > 0)
      return 1
    else
      return 0
    end
  end

  IgnoreFuel = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full)
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    if CanFuelBeUsedOrDemanded[y,f,r] == 1 && CanFuelBeProduced[y,f,r] == 0
      IgnoreFuel[y,f,r] = 1
    end
  end end end

  function PureDemandFuel(y, f, r);
    if CanFuelBeUsed(y,f,r) == 0 && Params.SpecifiedAnnualDemand[r,f,y] > 0
      return 1
    else
      return 0
    end
  end
  print("IgnoreFuel : ",Dates.now()-start,"\n")

   ###############
   # Constraints #
   ###############

  
   ############### Capacity Adequacy A #############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for  r ∈ Sets.Region_full
    cond= (any(x->x>0,[Params.TotalAnnualMaxCapacity[r,t,yy] for yy ∈ Sets.Year if (y - yy < Params.OperationalLife[r,t]) && (y-yy>= 0)])) && (Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
    if cond
      @constraint(model, model[:AccumulatedNewCapacity][y,t,r] == sum(model[:NewCapacity][yy,t,r] for yy ∈ Sets.Year if (y - yy < Params.OperationalLife[r,t]) && (y-yy>= 0)), base_name="CAa1_TotalNewCapacity_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:AccumulatedNewCapacity][y,t,r], 0; force=true)
    end
    if cond || (Params.ResidualCapacity[r,t,y]) > 0
      @constraint(model, model[:AccumulatedNewCapacity][y,t,r] + Params.ResidualCapacity[r,t,y] == model[:TotalCapacityAnnual][y,t,r], base_name="CAa2_TotalAnnualCapacity_$(y)_$(t)_$(r)")
    elseif !cond && (Params.ResidualCapacity[r,t,y]) == 0
      JuMP.fix(model[:TotalCapacityAnnual][y,t,r],0; force=true)
    end
  end end end

  print("Cstr: Cap Adequacy A1 : ",Dates.now()-start,"\n")

  CanBuildTechnology = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Technology), length(Sets.Region_full)), Sets.Year, Sets.Technology, Sets.Region_full)
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    temp=  (Params.TotalAnnualMaxCapacity[r,t,y] *
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y])
    if (temp > 0) && ((!JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]) && !JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) || (JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) > 0)) || (JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r]) && (JuMP.upper_bound(model[:TotalCapacityAnnual][y,t,r]) > 0)))
      CanBuildTechnology[y,t,r] = 1
    end
  end end end
#=   for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    temp=  (Params.TotalAnnualMaxCapacity[r,t,y] *
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y])
    #if (temp > 0) && JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) == 0)
    if JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]) && JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) == 0
      CanBuildTechnology[y,t,r] = 1
      if temp >0
        CanBuildTechnology[y,t,r] = 2
      end
    end
    if temp >0 && !(JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]) && JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) == 0)
      CanBuildTechnology[y,t,r] = 1.5
    end
  end end end =#
#=   function CanBuildTechnology(y,t,r)
    temp=  (Params.TotalAnnualMaxCapacity[r,t,y] *
    sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
    Params.AvailabilityFactor[r,t,y] * 
    Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y])
    if (!ismissing(temp)) && (temp > 0) && JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])
      return 1
    else
      return 0
    end
  end =#
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for  r ∈ Sets.Region_full for l ∈ Sets.Timeslice for m ∈ Sets.Mode_of_operation
    if ((Params.CapacityFactor[r,t,l,y] == 0)) ||
      (Params.AvailabilityFactor[r,t,y] == 0) ||
      (Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 0) ||
      (Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] == 0) ||
      (Params.TotalAnnualMaxCapacity[r,t,y] == 0) ||
      ((JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][y,t,r]) == 0)) ||
      ((JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) == 0))
        JuMP.fix(model[:RateOfActivity][y,l,t,m,r], 0; force=true)
    end
  end end end end end
  print("Cstr: Cap Adequacy A2 : ",Dates.now()-start,"\n")

  start=Dates.now()
  if Switch.switch_intertemporal == 1
    for r ∈ Sets.Region_full for l ∈ Sets.Timeslice for t ∈ Sets.Technology for y ∈ Sets.Year
      if Params.CapacityFactor[r,t,l,y] > 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
        @constraint(model,
        model[:RateOfTotalActivity][y,l,t,r] == model[:TotalActivityPerYear][r,l,t,y]*Params.AvailabilityFactor[r,t,y] - model[:DispatchDummy][r,l,t,y]*Params.TagDispatchableTechnology[t],
        base_name="CAa4_Constraint_Capacity_$(r)_$(l)_$(t)_$(y)")
      end
      if (sum(Params.CapacityFactor[r,t,l,yy] for yy ∈ Sets.Year if y-yy < Params.OperationalLife[r,t] && y-yy >= 0) > 0 || Params.CapacityFactor[r,t,l,Switch.StartYear] > 0) && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0
        @constraint(model,
        model[:TotalActivityPerYear][r,l,t,y] == sum(model[:NewCapacity][yy,t,r] * Params.CapacityFactor[r,t,l,yy] * Params.CapacityToActivityUnit[r,t] for yy ∈ Sets.Year if y-yy < Params.OperationalLife[r,t] && y-yy >= 0)+(Params.ResidualCapacity[r,t,y]*Params.CapacityFactor[r,t,l,Switch.StartYear] * Params.CapacityToActivityUnit[r,t]),
        base_name="CAaT_TotalActivityPerYear_Intertemporal_$(r)_$(l)_$(t)_$(y)")
      end
    end end end end

  else
    for y ∈ Sets.Year for t ∈ Sets.Technology for  r ∈ Sets.Region_full for l ∈ Sets.Timeslice
      if (Params.CapacityFactor[r,t,l,y] > 0) &&
        (Params.AvailabilityFactor[r,t,y] > 0) &&
        (Params.TotalAnnualMaxCapacity[r,t,y] > 0) &&
        (Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
          @constraint(model, sum(model[:RateOfActivity][y,l,t,m,r] for m ∈ Sets.Mode_of_operation) == model[:TotalCapacityAnnual][y,t,r] * Params.CapacityFactor[r,t,l,y] * Params.CapacityToActivityUnit[r,t] * Params.AvailabilityFactor[r,t,y] - model[:DispatchDummy][r,l,t,y] * Params.TagDispatchableTechnology[t],
          base_name="CAa4_Constraint_Capacity_$(r)_$(l)_$(t)_$(y)")
      end
    end end end end
  end
  print("Cstr: Cap Adequacy A3 : ",Dates.now()-start,"\n")

  # the parameters, variables and switch below are not defined and would need to be reimplemented
#=   if UseMipSolver == true
    @constraint(model, CAa5_TotalNewCapacity[y=Sets.Year,t=Sets.Technology,r=Sets.Region_full;Params.CapacityOfOneTechnologyUnit[y,t,r] != 0 && Params.AvailabilityFactor[r,t,y] > 0],
    Params.CapacityOfOneTechnologyUnit[y,t,r] * model[:NumberOfNewTechnologyUnits][y,t,r] == model[:NewCapacity][y,t,r])
  end =#

  
   ############### Capacity Adequacy B #############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for  r ∈ Sets.Region_full
    if (Params.AvailabilityFactor[r,t,y] < 1) &&
      (Params.TotalAnnualMaxCapacity[r,t,y] > 0) &&
      (Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0) &&
      (((JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][y,t,r]) > 0)) ||
      ((!JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (!JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]))) ||
      ((JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) > 0)))
      @constraint(model, sum(sum(model[:RateOfActivity][y,l,t,m,r]  for m ∈ Sets.Mode_of_operation) * Params.YearSplit[l,y] for l ∈ Sets.Timeslice) <= sum(model[:TotalCapacityAnnual][y,t,r]*Params.CapacityFactor[r,t,l,y]*Params.YearSplit[l,y]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t] for l ∈ Sets.Timeslice), base_name="CAb1_PlannedMaintenance_$(y)_$(t)_$(r)")
    end
  end end end
  print("Cstr: Cap Adequacy B : ",Dates.now()-start,"\n")
  
   ############### Energy Balance A #############
  
  start=Dates.now()
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    for rr ∈ Sets.Region_full
      if Params.TradeRoute[y,f,r,rr] > 0
        for l ∈ Sets.Timeslice
          @constraint(model, model[:Import][y,l,f,r,rr] == model[:Export][y,l,f,rr,r], base_name="EBa10_EnergyBalanceEachTS4_$(y)_$(l)_$(f)_$(r)_$(rr)")
        end
      else
        for l ∈ Sets.Timeslice
          JuMP.fix(model[:Import][y,l,f,r,rr], 0; force=true)
          JuMP.fix(model[:Export][y,l,f,rr,r], 0; force=true)
        end
      end
    end

    if sum(Params.TradeRoute[y,f,r,rr] for rr ∈ Sets.Region_full) == 0
      JuMP.fix.(model[:NetTrade][y,:,f,r], 0; force=true)
    else
      for l ∈ Sets.Timeslice
        @constraint(model, sum(model[:Export][y,l,f,r,rr]*(1+Params.TradeLossBetweenRegions[y,f,r,rr]) - model[:Import][y,l,f,r,rr] for rr ∈ Sets.Region_full if Params.TradeRoute[y,f,r,rr] > 0) == model[:NetTrade][y,l,f,r], 
        base_name="EBa12_NetTradeBalance_$(y)_$(l)_$(f)_$(r)")
      end
    end

    if IgnoreFuel[y,f,r] == 0
      for l ∈ Sets.Timeslice
        @constraint(model,sum(model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for (t,m) ∈ LoopSetOutput[(r,f,y)])* Params.YearSplit[l,y] ==
       (Params.Demand[y,l,f,r] + sum(model[:RateOfActivity][y,l,t,m,r]*Params.InputActivityRatio[r,t,f,m,y] for (t,m) ∈ LoopSetInput[(r,f,y)])*Params.YearSplit[l,y] + model[:NetTrade][y,l,f,r] + model[:Curtailment][y,l,f,r]),
        base_name="EBa11_EnergyBalanceEachTS5_$(y)_$(l)_$(f)_$(r)")
      end
    end
  end end end

   # test of a different formulation to compare performance with the formulation using loops
#=   @constraint(model,EBa10_EnergyBalanceEachTS4[y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full,rr=Sets.Region_full;Params.TradeRoute[y,f,r,rr] != 0],
  model[:Import][y,l,f,r,rr] == model[:Export][y,l,f,rr,r])
  cond = Params.TradeRoute[:,:,:,:] .== 0
  JuMP.fix.(model[:Import][y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full,rr=Sets.Region_full; Params.TradeRoute[y,f,r,rr] == 0], 0;force=true)
  JuMP.fix(model[:Export][y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full,rr=Sets.Region_full; Params.TradeRoute[y,f,r,rr] == 0], 0;force=true)

  JuMP.fix(model[:NetTrade][y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full; Params.TradeRoute[y,f,r,rr] == 0], 0;force=true)

  @constraint(model, EBa11_EnergyBalanceEachTS5[y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full; IgnoreFuel[y,f,r] == 0],
  sum(model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for t ∈ Sets.Technology for m ∈ Sets.Mode_of_operation)* Params.YearSplit[l,y] ==
  (Params.Demand[y,l,f,r] + sum(model[:RateOfActivity][y,l,t,m,r]*Params.InputActivityRatio[r,t,f,m,y] for t ∈ Sets.Technology for m ∈ Sets.Mode_of_operation)*Params.YearSplit[l,y] + model[:NetTrade][y,l,f,r] + model[:Curtailment][y,l,f,r]))

  @constraint(model, EBa12_NetTradeBalance[y=Sets.Year,l=Sets.Timeslice,f=Sets.Fuel,r=Sets.Region_full; sum(Params.TradeRoute[y,f,r,rr] for rr ∈ Sets.Region_full) == 0],
  sum(model[:Export][y,l,f,r,rr]*(1+Params.TradeLossBetweenRegions[y,f,r,rr]) - model[:Import][y,l,f,r,rr] for rr ∈ Sets.Region_full if Params.TradeRoute[y,f,r,rr] > 0) == model[:NetTrade][y,l,f,r])
 =#
  print("Cstr: Energy Balance A1 : ",Dates.now()-start,"\n")
  start=Dates.now()
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    if any(x->x>0, [JuMP.has_upper_bound(model[:Curtailment][y,l,f,r]) ? JuMP.upper_bound(model[:Curtailment][y,l,f,r]) : ((JuMP.is_fixed(model[:Curtailment][y,l,f,r])) && (JuMP.fix_value(model[:Curtailment][y,l,f,r]) == 0)) ? 0 : 999999 for l ∈ Sets.Timeslice])
      @constraint(model, model[:CurtailmentAnnual][y,f,r] == sum(model[:Curtailment][y,l,f,r] for l ∈ Sets.Timeslice), base_name="EBa13_CurtailmentAnnual_$(y)_$(f)_$(r)")
    else
      JuMP.fix(model[:CurtailmentAnnual][y,f,r],0; force=true)
    end

    if Params.SelfSufficiency[y,f,r] != 0
      @constraint(model, sum(model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for l ∈ Sets.Timeslice for (t,m) ∈ LoopSetOutput[(r,f,y)]) == (Params.SpecifiedAnnualDemand[r,f,y] + sum(model[:RateOfActivity][y,l,t,m,r]*Params.InputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for l ∈ Sets.Timeslice for (t,m) ∈ LoopSetInput[(r,f,y)]))*Params.SelfSufficiency[y,f,r], base_name="EBa14_SelfSufficiency_$(y)_$(f)_$(r)")
    end
  end end end 
  print("Cstr: Energy Balance A2 : ",Dates.now()-start,"\n")

   ############### Energy Balance B #############
  
  start=Dates.now()
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    if sum(Params.TradeRoute[y,f,r,rr] for rr ∈ Sets.Region_full) > 0
      @constraint(model, sum(model[:NetTrade][y,l,f,r] for l ∈ Sets.Timeslice) == model[:NetTradeAnnual][y,f,r], base_name="EBb3_EnergyBalanceEachYear3_$(y)_$(f)_$(r)")
    else
      JuMP.fix(model[:NetTradeAnnual][y,f,r],0; force=true)
    end
  
    @constraint(model, sum(model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for l ∈ Sets.Timeslice for (t,m) ∈ LoopSetOutput[(r,f,y)]) >= 
    sum( model[:RateOfActivity][y,l,t,m,r]*Params.InputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for l ∈ Sets.Timeslice for (t,m) ∈ LoopSetInput[(r,f,y)]) + model[:NetTradeAnnual][y,f,r], 
    base_name="EBb4_EnergyBalanceEachYear4_$(y)_$(f)_$(r)")
  end end end
  print("Cstr: Energy Balance B : ",Dates.now()-start,"\n")

  
   ############### Trade Capacities & Investments #############
  
  for i ∈ 1:length(Sets.Year) for r ∈ Sets.Region_full for rr ∈ Sets.Region_full
    if Params.TradeRoute[Sets.Year[i],"Power",rr,r] > 0
      for l ∈ Sets.Timeslice
        @constraint(model, (model[:Import][Sets.Year[i],l,"Power",r,rr]) <= model[:TotalTradeCapacity][Sets.Year[i],"Power",rr,r]*Params.YearSplit[l,Sets.Year[i]]*31.536 , base_name="TrC1_TradeCapacityPowerLinesImport_$(Sets.Year[i])_$(l)_Power_$(r)_$(rr)")
      end
    end
    if Params.TradeRoute[Sets.Year[i],"Power",r,rr] > 0
      for l ∈ Sets.Timeslice
        @constraint(model, (model[:Export][Sets.Year[i],l,"Power",r,rr]) <= model[:TotalTradeCapacity][Sets.Year[i],"Power",r,rr]*Params.YearSplit[l,Sets.Year[i]]*31.536 , base_name="TrC1_TradeCapacityPowerLinesExport_$(Sets.Year[i])_$(l)_Power_$(r)_$(rr)")
      end
      @constraint(model, model[:NewTradeCapacity][Sets.Year[i],"Power",r,rr]*Params.TradeCapacityGrowthCosts["Power",r,rr]*Params.TradeRoute[Sets.Year[i],"Power",r,rr] == model[:NewTradeCapacityCosts][Sets.Year[i],"Power",r,rr], base_name="TrC4_NewTradeCapacityCosts_$(Sets.Year[i])_Power_$(r)_$(rr)")
      @constraint(model, model[:NewTradeCapacityCosts][Sets.Year[i],"Power",r,rr]/((1+Settings.GeneralDiscountRate[r])^(Sets.Year[i]-Switch.StartYear+0.5)) == model[:DiscountedNewTradeCapacityCosts][Sets.Year[i],"Power",r,rr], base_name="TrC5_DiscountedNewTradeCapacityCosts_$(Sets.Year[i])_Power_$(r)_$(rr)")
    end

    if Switch.switch_dispatch == 0
      for f ∈ Sets.Fuel
        if Params.TradeRoute[Sets.Year[i],f,r,rr] > 0
          if Sets.Year[i] == Switch.StartYear
            @constraint(model, model[:TotalTradeCapacity][Sets.Year[i],f,r,rr] == Params.TradeCapacity[Sets.Year[i],f,r,rr], base_name="TrC2a_TotalTradeCapacity_$(Sets.Year[i])_$(f)_$(r)_$(rr)")
          elseif Sets.Year[i] > Switch.StartYear
            @constraint(model, model[:TotalTradeCapacity][Sets.Year[i],f,r,rr] == model[:TotalTradeCapacity][Sets.Year[i-1],f,r,rr] + model[:NewTradeCapacity][Sets.Year[i],f,r,rr] + Params.AdditionalTradeCapacity[Sets.Year[i],f,r,rr], 
            base_name="TrC2b_TotalTradeCapacity_$(Sets.Year[i])_$(f)_$(r)_$(rr)")
          end

          if i > 1 && Params.GrowthRateTradeCapacity[Sets.Year[i],f,r,rr] > 0 && Params.TradeRoute[Sets.Year[i],f,r,rr] > 0
            @constraint(model, (Params.GrowthRateTradeCapacity[Sets.Year[i],f,r,rr]*YearlyDifferenceMultiplier(Sets.Year[i],Sets))*model[:TotalTradeCapacity][Sets.Year[i-1],f,r,rr] >= model[:NewTradeCapacity][Sets.Year[i],f,r,rr], 
            base_name="TrC3_NewTradeCapacityLimit_$(Sets.Year[i])_$(f)_$(r)_$(rr)")
          end
        end
      end
    end

    if Params.TradeRoute[Sets.Year[i],"Power",r,rr] == 0 || Params.GrowthRateTradeCapacity[Sets.Year[i],"Power",r,rr] == 0
      JuMP.fix(model[:NewTradeCapacity][Sets.Year[i],"Power",r,rr],0; force=true)
    end

    for f ∈ Sets.Fuel
      if f != "Power"
        JuMP.fix(model[:NewTradeCapacity][Sets.Year[i],f,r,rr],0; force=true)
      end
      if Params.TradeRoute[Sets.Year[i],f,r,rr] == 0 || f != "Power"
        JuMP.fix(model[:DiscountedNewTradeCapacityCosts][Sets.Year[i],f,r,rr],0; force=true)
      end
    end
  end end end


  
   ############### Trading Costs #############
  

  for y ∈ Sets.Year for r ∈ Sets.Region_full
    if sum(Params.TradeRoute[y,f,r,rr] for f ∈ Sets.Fuel for rr ∈ Sets.Region_full) > 0
      @constraint(model, sum(model[:Import][y,l,f,r,rr] * Params.TradeCosts[f,r,rr] for f ∈ Sets.Fuel for rr ∈ Sets.Region_full for l ∈ Sets.Timeslice if Params.TradeRoute[y,f,r,rr] > 0) == model[:AnnualTotalTradeCosts][y,r], base_name="Tc1_TradeCosts_$(y)_$(r)")
    else
      JuMP.fix(model[:AnnualTotalTradeCosts][y,r], 0; force=true)
    end
    @constraint(model, model[:AnnualTotalTradeCosts][y,r]/((1+Settings.GeneralDiscountRate[r])^(y-Switch.StartYear+0.5)) == model[:DiscountedAnnualTotalTradeCosts][y,r], base_name="Tc3_DiscountedAnnualTradeCosts_$(y)_$(r)")
  end end 

  
   ############### Accounting Technology Production/Use #############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for  r ∈ Sets.Region_full for m ∈ Sets.Mode_of_operation
    if CanBuildTechnology[y,t,r] > 0
      @constraint(model, sum(model[:RateOfActivity][y,l,t,m,r]*Params.YearSplit[l,y] for l ∈ Sets.Timeslice) == model[:TotalAnnualTechnologyActivityByMode][y,t,m,r], base_name="Acc3_AverageAnnualRateOfActivity_$(y)_$(t)_$(m)_$(r)")
    else
      JuMP.fix(model[:TotalAnnualTechnologyActivityByMode][y,t,m,r],0; force=true)
    end
  end end end end 
  print("Cstr: Acc. Tech. 1 : ",Dates.now()-start,"\n")
  start=Dates.now()
  for r ∈ Sets.Region_full
    @constraint(model, sum(model[:TotalDiscountedCost][y,r] for y ∈ Sets.Year) == model[:ModelPeriodCostByRegion][r], base_name="Acc4_ModelPeriodCostByRegion_$(r)")
  end
  print("Cstr: Acc. Tech. 2 : ",Dates.now()-start,"\n")
  
   ############### Capital Costs #############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    @constraint(model, Params.CapitalCost[r,t,y] * model[:NewCapacity][y,t,r] == model[:CapitalInvestment][y,t,r], base_name="CC1_UndiscountedCapitalInvestment_$(y)_$(t)_$(r)")
    @constraint(model, model[:CapitalInvestment][y,t,r]/((1+Settings.TechnologyDiscountRate[r,t])^(y-Switch.StartYear)) == model[:DiscountedCapitalInvestment][y,t,r], base_name="CC2_DiscountingCapitalInvestment_$(y)_$(t)_$(r)")
  end end end
  print("Cstr: Cap. Cost. : ",Dates.now()-start,"\n")
  
   ############### Investment & Capacity Limits #############
  
  if Switch.switch_dispatch == 0
    if Switch.switch_investLimit == 1
      for i ∈ 1:length(Sets.Year)
        if Sets.Year[i] > Switch.StartYear
          @constraint(model, 
          sum(model[:CapitalInvestment][Sets.Year[i],t,r] for t ∈ Sets.Technology for r ∈ Sets.Region_full) <= 1/(max(Sets.Year...)-Switch.StartYear)*YearlyDifferenceMultiplier(Sets.Year[i-1],Sets)*Settings.InvestmentLimit*sum(model[:CapitalInvestment][yy,t,r] for yy ∈Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full), 
          base_name="CC3_InvestmentLimit_$(Sets.Year[i])")
          for r ∈ Sets.Region_full 
            for t ∈ Subsets.Renewables
              @constraint(model,
              model[:NewCapacity][Sets.Year[i],t,r] <= YearlyDifferenceMultiplier(Sets.Year[i-1],Sets)*Settings.NewRESCapacity*Params.TotalAnnualMaxCapacity[r,t,Sets.Year[i]], 
              base_name="CC4_CapacityLimit_$(Sets.Year[i])_$(r)_$(t)")
            end
            for f ∈ Sets.Fuel
              for t ∈ Subsets.PhaseInSet
                @constraint(model,
                model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r] >= model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r]*Settings.PhaseIn[Sets.Year[i]]*(Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]] > 0 ? Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]]/Params.SpecifiedAnnualDemand[r,f,Sets.Year[i-1]] : 1), 
                base_name="CC5c_PhaseInLowerLimit_$(Sets.Year[i])_$(r)_$(t)_$(f)")
              end
              for t ∈ Subsets.PhaseOutSet
                @constraint(model, 
                model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r] <= model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r]*Settings.PhaseOut[Sets.Year[i]]*(Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]] > 0 ? Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]]/Params.SpecifiedAnnualDemand[r,f,Sets.Year[i-1]] : 1), 
                base_name="CC5d_PhaseOutUpperLimit_$(Sets.Year[i])_$(r)_$(t)_$(f)")
              end
            end
          end
          for f ∈ Sets.Fuel
            if Settings.ProductionGrowthLimit[Sets.Year[i],f]>0
              @constraint(model,
              sum(model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r]-model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Sets.Technology for r ∈ Sets.Region_full if Params.RETagTechnology[r,t,Sets.Year[i]]==1) <= 
              YearlyDifferenceMultiplier(Sets.Year[i-1],Sets)*Settings.ProductionGrowthLimit[Sets.Year[i],f]*sum(model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Sets.Technology for r ∈ Sets.Region_full)-sum(model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Subsets.StorageDummies for r ∈ Sets.Region_full),
              base_name="CC5f_AnnualProductionChangeLimit_$(Sets.Year[i])_$(f)")
            end
          end
        end
      end
    

      if Switch.switch_ccs == 1
        for r ∈ Sets.Region_full
          for i ∈ 2:length(Sets.Year) for f ∈ setdiff(Sets.Fuel,["DAC_Dummy"]) 
            @constraint(model,
            sum(model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r]-model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Subsets.CCS) <= YearlyDifferenceMultiplier(Sets.Year[i-1],Sets)*(Settings.ProductionGrowthLimit[Sets.Year[i],"Air"])*sum(model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Sets.Technology),
            base_name="CC5g_CCSAddition_$(Sets.Year[i])_$(r)_$(f)")
          end end

          if sum(Params.RegionalCCSLimit[r] for r ∈ Sets.Region_full)>0
            @constraint(model,
            sum(sum( model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*Params.EmissionContentPerFuel[f,e]*Params.InputActivityRatio[r,t,f,m,y]*YearlyDifferenceMultiplier(y,Sets)*((Params.EmissionActivityRatio[r,t,e,m,y]>0 ? (1-Params.EmissionActivityRatio[r,t,e,m,y]) : 0)+
            (Params.EmissionActivityRatio[r,t,e,m,y] < 0 ? (-1)*Params.EmissionActivityRatio[r,t,e,m,y] : 0)) for f ∈ Sets.Fuel for m ∈ Sets.Mode_of_operation for e ∈ Sets.Emission) for y ∈ Sets.Year for t ∈ Subsets.CCS ) <= Params.RegionalCCSLimit[r],
            base_name="CC5i_CCSLimit_$(r)")
          end
        end
      end

      for i ∈ 2:length(Sets.Year) for f ∈ Sets.Fuel
        if Settings.ProductionGrowthLimit[Sets.Year[i],f]>0
          for r ∈ Sets.Region_full 
            @constraint(model,
            sum(model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r]-model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Subsets.StorageDummies) <= YearlyDifferenceMultiplier(Sets.Year[i-1],Sets)*(Settings.ProductionGrowthLimit[Sets.Year[i],f]+Settings.StorageLimitOffset)*sum(model[:ProductionByTechnologyAnnual][Sets.Year[i-1],t,f,r] for t ∈ Sets.Technology),
            base_name="CC5h_AnnualStorageChangeLimit_$(Sets.Year[i])_$(r)_$(f)")
          end
        end
      end end
    end
  end

  
   ############### Salvage Value #############
  
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if Settings.DepreciationMethod[r]==1 && ((y + Params.OperationalLife[r,t] - 1 > max(Sets.Year...)) && (Settings.TechnologyDiscountRate[r,t] > 0))
      @constraint(model, 
      model[:SalvageValue][y,t,r] == Params.CapitalCost[r,t,y]*model[:NewCapacity][y,t,r]*(1-(((1+Settings.TechnologyDiscountRate[r,t])^(max(Sets.Year...) - y + 1 ) -1)/((1+Settings.TechnologyDiscountRate[r,t])^Params.OperationalLife[r,t]-1))),
      base_name="SV1_SalvageValueAtEndOfPeriod1_$(y)_$(t)_$(r)")
    end

    if (((y + Params.OperationalLife[r,t]-1 > max(Sets.Year...)) && (Settings.TechnologyDiscountRate[r,t] == 0)) || (Settings.DepreciationMethod[r]==2 && (y + Params.OperationalLife[r,t]-1 > max(Sets.Year...))))
      @constraint(model,
      model[:SalvageValue][y,t,r] == Params.CapitalCost[r,t,y]*model[:NewCapacity][y,t,r]*(1-(max(Sets.Year...)- y+1)/Params.OperationalLife[r,t]),
      base_name="SV2_SalvageValueAtEndOfPeriod2_$(y)_$(t)_$(r)")
    end
    if y + Params.OperationalLife[r,t]-1 <= max(Sets.Year...)
      @constraint(model,
      model[:SalvageValue][y,t,r] == 0,
      base_name="SV3_SalvageValueAtEndOfPeriod3_$(y)_$(t)_$(r)")
    end

    @constraint(model,
    model[:DiscountedSalvageValue][y,t,r] == model[:SalvageValue][y,t,r]/((1+Settings.TechnologyDiscountRate[r,t])^(1+max(Sets.Year...) - Switch.StartYear)),
    base_name="SV4_SalvageValueDiscToStartYr_$(y)_$(t)_$(r)")
  end end end

  
   ############### Operating Costs #############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if (sum(Params.VariableCost[r,t,m,y] for m ∈ Sets.Mode_of_operation) > 0) & (CanBuildTechnology[y,t,r] > 0)
      @constraint(model, sum((model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*Params.VariableCost[r,t,m,y]) for m ∈ Sets.Mode_of_operation) == model[:AnnualVariableOperatingCost][y,t,r], base_name="OC1_OperatingCostsVariable_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:AnnualVariableOperatingCost][y,t,r],0; force=true)
    end

    if (Params.FixedCost[r,t,y] > 0) & (CanBuildTechnology[y,t,r] > 0)
      @constraint(model, sum(model[:NewCapacity][yy,t,r]*Params.FixedCost[r,t,yy] for yy ∈ Sets.Year if (y-yy < Params.OperationalLife[r,t]) && (y-yy >= 0)) == model[:AnnualFixedOperatingCost][y,t,r], base_name="OC2_OperatingCostsFixedAnnual_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:AnnualFixedOperatingCost][y,t,r],0; force=true)
    end

    if ((JuMP.has_upper_bound(model[:AnnualVariableOperatingCost][y,t,r]) && JuMP.upper_bound(model[:AnnualVariableOperatingCost][y,t,r]) >0) || 
      (!JuMP.is_fixed(model[:AnnualVariableOperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(model[:AnnualVariableOperatingCost][y,t,r]) ||
      (JuMP.is_fixed(model[:AnnualVariableOperatingCost][y,t,r]) && JuMP.fix_value(model[:AnnualVariableOperatingCost][y,t,r]) >0)) ||
      ((JuMP.has_upper_bound(model[:AnnualFixedOperatingCost][y,t,r]) && JuMP.upper_bound(model[:AnnualFixedOperatingCost][y,t,r]) >0) || 
      (!JuMP.is_fixed(model[:AnnualFixedOperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(model[:AnnualFixedOperatingCost][y,t,r]) ||
      (JuMP.is_fixed(model[:AnnualFixedOperatingCost][y,t,r]) && JuMP.fix_value(model[:AnnualFixedOperatingCost][y,t,r]) >0)) #OC3_OperatingCostsTotalAnnual
      @constraint(model, (model[:AnnualFixedOperatingCost][y,t,r] + model[:AnnualVariableOperatingCost][y,t,r])*YearlyDifferenceMultiplier(y,Sets) == model[:OperatingCost][y,t,r], base_name="OC3_OperatingCostsTotalAnnual_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:OperatingCost][y,t,r],0; force=true)
    end

    if ((JuMP.has_upper_bound(model[:OperatingCost][y,t,r]) && JuMP.upper_bound(model[:OperatingCost][y,t,r]) >0) || 
      (!JuMP.is_fixed(model[:OperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(model[:OperatingCost][y,t,r]) ||
      (JuMP.is_fixed(model[:OperatingCost][y,t,r]) && JuMP.fix_value(model[:OperatingCost][y,t,r]) >0)) # OC4_DiscountedOperatingCostsTotalAnnual
      @constraint(model, model[:OperatingCost][y,t,r]/((1+Settings.TechnologyDiscountRate[r,t])^(y-Switch.StartYear+0.5)) == model[:DiscountedOperatingCost][y,t,r], base_name="OC4_DiscountedOperatingCostsTotalAnnual_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:DiscountedOperatingCost][y,t,r],0; force=true)
    end
  end end end
  print("Cstr: Op. Cost. : ",Dates.now()-start,"\n")
  
   ############### Total Discounted Costs #############
  
  start=Dates.now()
  for y ∈ Sets.Year for r ∈ Sets.Region_full
    for t ∈ Sets.Technology 
      @constraint(model,
      model[:DiscountedOperatingCost][y,t,r]+model[:DiscountedCapitalInvestment][y,t,r]+model[:DiscountedTechnologyEmissionsPenalty][y,t,r]-model[:DiscountedSalvageValue][y,t,r]
      + (Switch.switch_ramping ==1 ? model[:DiscountedAnnualProductionChangeCost][y,t,r] : 0)
      == model[:TotalDiscountedCostByTechnology][y,t,r],
      base_name="TDC1_TotalDiscountedCostByTechnology_$(y)_$(t)_$(r)")
    end
    @constraint(model, sum(model[:TotalDiscountedCostByTechnology][y,t,r] for t ∈ Sets.Technology)+sum(model[:TotalDiscountedStorageCost][s,y,r] for s ∈ Sets.Storage) == model[:TotalDiscountedCost][y,r]
    ,base_name="TDC2_TotalDiscountedCost_$(y)_$(r)")
  end end
    print("Cstr: Tot. Disc. Cost 2 : ",Dates.now()-start,"\n")
  
   ############### Total Capacity Constraints ##############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if (Params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (Params.TotalAnnualMaxCapacity[r,t,y] > 0)
      @constraint(model, model[:TotalCapacityAnnual][y,t,r] <= Params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_TotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")
    elseif Params.TotalAnnualMaxCapacity[r,t,y] == 0
      JuMP.fix(model[:TotalCapacityAnnual][y,t,r],0; force=true)
    end

    if Params.TotalAnnualMinCapacity[r,t,y]>0
      @constraint(model, model[:TotalCapacityAnnual][y,t,r] >= Params.TotalAnnualMinCapacity[r,t,y], base_name="TCC2_TotalAnnualMinCapacityConstraint_$(y)_$(t)_$(r)")
    end
  end end end
  print("Cstr: Tot. Cap. : ",Dates.now()-start,"\n")
  
   ############### New Capacity Constraints ##############
  
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if Params.TotalAnnualMaxCapacityInvestment[r,t,y] < 999999
      @constraint(model,
      model[:NewCapacity][y,t,r] <= Params.TotalAnnualMaxCapacityInvestment[r,t,y], base_name="NCC1_TotalAnnualMaxNewCapacityConstraint_$(y)_$(t)_$(r)")
    end
    if Params.TotalAnnualMinCapacityInvestment[r,t,y] > 0
      @constraint(model,
      model[:NewCapacity][y,t,r] >= Params.TotalAnnualMinCapacityInvestment[r,t,y], base_name="NCC2_TotalAnnualMinNewCapacityConstraint_$(y)_$(t)_$(r)")
    end
  end end end

  
   ################ Annual Activity Constraints ##############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if (CanBuildTechnology[y,t,r] > 0) && 
      (any(x->x>0, [JuMP.has_upper_bound(model[:ProductionByTechnologyAnnual][y,t,f,r]) ? JuMP.upper_bound(model[:ProductionByTechnologyAnnual][y,t,f,r]) : ((JuMP.is_fixed(model[:ProductionByTechnologyAnnual][y,t,f,r])) && (JuMP.fix_value(model[:ProductionByTechnologyAnnual][y,t,f,r]) == 0)) ? 0 : 999999 for f ∈ Sets.Fuel]))
      @constraint(model, sum(model[:ProductionByTechnologyAnnual][y,t,f,r] for f ∈ Sets.Fuel) == model[:TotalTechnologyAnnualActivity][y,t,r], base_name= "AAC1_TotalAnnualTechnologyActivity_$(y)_$(t)_$(r)")
    else
      JuMP.fix(model[:TotalTechnologyAnnualActivity][y,t,r],0; force=true)
    end

    if Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] < 999999
      @constraint(model, model[:TotalTechnologyAnnualActivity][y,t,r] <= Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y], base_name= "AAC2_TotalAnnualTechnologyActivityUpperLimit_$(y)_$(t)_$(r)")
    end

    if Params.TotalTechnologyAnnualActivityLowerLimit[r,t,y] > 0 # AAC3_TotalAnnualTechnologyActivityLowerLimit
      @constraint(model, model[:TotalTechnologyAnnualActivity][y,t,r] >= Params.TotalTechnologyAnnualActivityLowerLimit[r,t,y], base_name= "AAC3_TotalAnnualTechnologyActivityLowerLimit_$(y)_$(t)_$(r)")
    end
  end end end 
  print("Cstr: Annual. Activity : ",Dates.now()-start,"\n")
  
   ################ Total Activity Constraints ##############
  
  start=Dates.now()
  for t ∈ Sets.Technology for r ∈ Sets.Region_full
    @constraint(model, sum(model[:TotalTechnologyAnnualActivity][y,t,r]*YearlyDifferenceMultiplier(y,Sets) for y ∈ Sets.Year) == model[:TotalTechnologyModelPeriodActivity][t,r], base_name="TAC1_TotalModelHorizenTechnologyActivity_$(t)_$(r)")
    if Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] < 999999
      @constraint(model, model[:TotalTechnologyModelPeriodActivity][t,r] <= Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t], base_name= "TAC2_TotalModelHorizenTechnologyActivityUpperLimit_$(t)_$(r)")
    end
    if Params.TotalTechnologyModelPeriodActivityLowerLimit[r,t] > 0
      @constraint(model, model[:TotalTechnologyModelPeriodActivity][t,r] >= Params.TotalTechnologyModelPeriodActivityLowerLimit[r,t], base_name= "TAC3_TotalModelHorizenTechnologyActivityLowerLimit_$(t)_$(r)")
    end
  end end
  print("Cstr: Tot. Activity : ",Dates.now()-start,"\n")
  
   ############### Reserve Margin Constraint ############## NTS: Should change demand for production
  
  if Switch.switch_dispatch == 0 

    for r ∈ Sets.Region_full for y ∈ Sets.Year for l ∈ Sets.Timeslice
      @constraint(model,
      sum((model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] * Params.YearSplit[l,y] *Params.ReserveMarginTagTechnology[r,t,y] * Params.ReserveMarginTagFuel[r,f,y]) for f ∈ Sets.Fuel for (t,m) ∈ LoopSetOutput[(r,f,y)]) == model[:TotalActivityInReserveMargin][r,y,l],
      base_name="RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units_$(y)_$(l)_$(r)")
      
      @constraint(model,
      sum((sum(model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for (t,m) ∈ LoopSetOutput[(r,f,y)]) * Params.YearSplit[l,y] *Params.ReserveMarginTagFuel[r,f,y]) for f ∈ Sets.Fuel) == model[:DemandNeedingReserveMargin][y,l,r],
      base_name="RM2_ReserveMargin_FuelsIncluded_$(y)_$(l)_$(r)")

      if Params.ReserveMargin[r,y] > 0
        @constraint(model,
        model[:DemandNeedingReserveMargin][y,l,r] * Params.ReserveMargin[r,y] <= model[:TotalActivityInReserveMargin][r,y,l],
        base_name="RM3_ReserveMargin_Constraint_$(y)_$(l)_$(r)")
      end
    end end end

  end
  
   ############### RE Production Target ############## NTS: Should change demand for production
  
  start=Dates.now()
  for i ∈ 1:length(Sets.Year) for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    for t ∈ Sets.Technology 
      if sum(Params.OutputActivityRatio[r,t,f,m,Sets.Year[i]] for m ∈ Sets.Mode_of_operation) > 0 &&
        Params.AvailabilityFactor[r,t,Sets.Year[i]] > 0 &&
        Params.TotalAnnualMaxCapacity[r,t,Sets.Year[i]] > 0 &&
        Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (!JuMP.is_fixed(model[:TotalCapacityAnnual][Sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][Sets.Year[i],t,r]) > 0)))
        @constraint(model, sum(sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,Sets.Year[i]] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,Sets.Year[i]] != 0)* Params.YearSplit[l,Sets.Year[i]] for l ∈ Sets.Timeslice) == model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r], base_name= "RE1_FuelProductionByTechnologyAnnual_$(Sets.Year[i])_$(t)_$(f)_$(r)")
      else
        JuMP.fix(model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r],0;force=true)
      end

      if sum(Params.InputActivityRatio[r,t,f,m,Sets.Year[i]] for m ∈ Sets.Mode_of_operation) > 0 &&
        Params.AvailabilityFactor[r,t,Sets.Year[i]] > 0 &&
        Params.TotalAnnualMaxCapacity[r,t,Sets.Year[i]] > 0 &&
        Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (!JuMP.is_fixed(model[:TotalCapacityAnnual][Sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(model[:TotalCapacityAnnual][Sets.Year[i],t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][Sets.Year[i],t,r]) > 0)))
        @constraint(model, sum(sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r]*Params.InputActivityRatio[r,t,f,m,Sets.Year[i]] for m ∈ Sets.Mode_of_operation if Params.InputActivityRatio[r,t,f,m,Sets.Year[i]] != 0)* Params.YearSplit[l,Sets.Year[i]] for l ∈ Sets.Timeslice) == model[:UseByTechnologyAnnual][Sets.Year[i],t,f,r], base_name= "RE5_FuelUseByTechnologyAnnual_$(Sets.Year[i])_$(t)_$(f)_$(r)")
      else
        JuMP.fix(model[:UseByTechnologyAnnual][Sets.Year[i],t,f,r],0;force=true)
      end
    end

    @constraint(model,
    sum(model[:ProductionByTechnologyAnnual][Sets.Year[i],t,f,r] for t ∈ Subsets.Renewables ) == model[:TotalREProductionAnnual][Sets.Year[i],r,f],base_name="RE2_TechIncluded_$(Sets.Year[i])_$(r)_$(f)")

    @constraint(model,
    Params.REMinProductionTarget[r,f,Sets.Year[i]]*sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,Sets.Year[i]]*Params.YearSplit[l,Sets.Year[i]] for l ∈ Sets.Timeslice for t ∈ Sets.Technology for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,Sets.Year[i]] != 0 )*Params.RETagFuel[r,f,Sets.Year[i]] <= model[:TotalREProductionAnnual][Sets.Year[i],r,f],
    base_name="RE4_EnergyConstraint_$(Sets.Year[i])_$(r)_$(f)")

    if Switch.switch_dispatch == 0
      if Sets.Year[i]> Switch.StartYear && Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]]>0
        @constraint(model,
        model[:TotalREProductionAnnual][Sets.Year[i],r,f] >= model[:TotalREProductionAnnual][Sets.Year[i-1],r,f]*((Params.SpecifiedAnnualDemand[r,f,Sets.Year[i]]/Params.SpecifiedAnnualDemand[r,f,Sets.Year[i-1]])),
        base_name="RE6_RETargetPath_$(Sets.Year[i])_$(r)_$(f)")
      end
    end

  end end end
  print("Cstr: RE target : ",Dates.now()-start,"\n")
  
   ################ Emissions Accounting ##############
  
  start=Dates.now()
  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if CanBuildTechnology[y,t,r] > 0
      for e ∈ Sets.Emission for m ∈ Sets.Mode_of_operation
        @constraint(model, Params.EmissionActivityRatio[r,t,e,m,y]*sum((model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*Params.EmissionContentPerFuel[f,e]*Params.InputActivityRatio[r,t,f,m,y]) for f ∈ Sets.Fuel) == model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] , base_name="E1_AnnualEmissionProductionByMode_$(y)_$(t)_$(e)_$(m)_$(r)" )
      end end
    else
      for m ∈ Sets.Mode_of_operation for e ∈ Sets.Emission
        JuMP.fix(model[:AnnualTechnologyEmissionByMode][y,t,e,m,r],0; force=true)
      end end
    end
  end end end
  print("Cstr: Em. Acc. 1 : ",Dates.now()-start,"\n")
  start=Dates.now()
  for y ∈ Sets.Year for r ∈ Sets.Region_full
    for t ∈ Sets.Technology
      for e ∈ Sets.Emission
        @constraint(model, sum(model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] for m ∈ Sets.Mode_of_operation) == model[:AnnualTechnologyEmission][y,t,e,r],
        base_name="E2_AnnualEmissionProduction_$(y)_$(t)_$(e)_$(r)")

        @constraint(model, (model[:AnnualTechnologyEmission][y,t,e,r]*Params.EmissionsPenalty[r,e,y]*Params.EmissionsPenaltyTagTechnology[r,t,e,y])*YearlyDifferenceMultiplier(y,Sets) == model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r],
        base_name="E3_EmissionsPenaltyByTechAndEmission_$(y)_$(t)_$(e)_$(r)")
      end

      @constraint(model, sum(model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r] for e ∈ Sets.Emission) == model[:AnnualTechnologyEmissionsPenalty][y,t,r],
      base_name="E4_EmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")

      @constraint(model, model[:AnnualTechnologyEmissionsPenalty][y,t,r]/((1+Settings.SocialDiscountRate[r])^(y-Switch.StartYear+0.5)) == model[:DiscountedTechnologyEmissionsPenalty][y,t,r],
      base_name="E5_DiscountedEmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")
    end
  end end 

  for e ∈ Sets.Emission
    for y ∈ Sets.Year
      for r ∈ Sets.Region_full
        @constraint(model, sum(model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ Sets.Technology) == model[:AnnualEmissions][y,e,r], 
        base_name="E6_EmissionsAccounting1_$(y)_$(e)_$(r)")

        @constraint(model, model[:AnnualEmissions][y,e,r]+Params.AnnualExogenousEmission[r,e,y] <= Params.RegionalAnnualEmissionLimit[r,e,y], 
        base_name="E8_RegionalAnnualEmissionsLimit_$(y)_$(e)_$(r)")
      end
      @constraint(model, sum(model[:AnnualEmissions][y,e,r]+Params.AnnualExogenousEmission[r,e,y] for r ∈ Sets.Region_full) <= Params.AnnualEmissionLimit[e,y],
      base_name="E9_AnnualEmissionsLimit_$(y)_$(e)")
    end
    @constraint(model, sum(model[:ModelPeriodEmissions][e,r] for r ∈ Sets.Region_full) <= Params.ModelPeriodEmissionLimit[e],
    base_name="E10_ModelPeriodEmissionsLimit_$(e)")
  end

  print("Cstr: Em. Acc. 2 : ",Dates.now()-start,"\n")
  start=Dates.now()
  for e ∈ Sets.Emission for r ∈ Sets.Region_full
    if Params.RegionalModelPeriodEmissionLimit[e,r] < 999999
      @constraint(model, model[:ModelPeriodEmissions][e,r] <= Params.RegionalModelPeriodEmissionLimit[e,r] ,base_name="E11_RegionalModelPeriodEmissionsLimit" )
    end
  end end
  print("Cstr: Em. Acc. 3 : ",Dates.now()-start,"\n")
  start=Dates.now()

  if Switch.switch_weighted_emissions == 1
    for e ∈ Sets.Emission for r ∈ Sets.Region_full
      @constraint(model,
      sum(model[:WeightedAnnualEmissions][Sets.Year[i],e,r]*(Sets.Year[i+1]-Sets.Year[i]) for i ∈ 1:length(Sets.Year)-1 if Sets.Year[i+1]-Sets.Year[i] > 0) +  model[:WeightedAnnualEmissions][Sets.Year[end],e,r] == model[:ModelPeriodEmissions][e,r]- Params.ModelPeriodExogenousEmission[r,e],
      base_name="E7_EmissionsAccounting2_$(e)_$(r)")

      @constraint(model,
      model[:AnnualEmissions][Sets.Year[end],e,r] == model[:WeightedAnnualEmissions][Sets.Year[end],e,r],
      base_name="E12b_WeightedLastYearEmissions_$(Sets.Year[end])_$(e)_$(r)")
      for i ∈ 1:length(Sets.Year)-1
        @constraint(model,
        (model[:AnnualEmissions][Sets.Year[i],e,r]+model[:AnnualEmissions][Sets.Year[i+1],e,r])/2 == model[:WeightedAnnualEmissions][Sets.Year[i],e,r],
        base_name="E12a_WeightedEmissions_$(Sets.Year[i])_$(e)_$(r)")
      end
    end end
  else
    for e ∈ Sets.Emission for r ∈ Sets.Region_full
      @constraint(model, sum( model[:AnnualEmissions][Sets.Year[ind],e,r]*(Sets.Year[ind+1]-Sets.Year[ind]) for ind ∈ 1:(length(Sets.Year)-1) if Sets.Year[ind+1]-Sets.Year[ind]>0)
      +  model[:AnnualEmissions][Sets.Year[end],e,r] == model[:ModelPeriodEmissions][e,r]- Params.ModelPeriodExogenousEmission[r,e],
      base_name="E7_EmissionsAccounting2_$(e)_$(r)")
    end end
  end
  print("Cstr: Em. Acc. 4 : ",Dates.now()-start,"\n")
  
   ################ Sectoral Emissions Accounting ##############
  start=Dates.now()

  for y ∈ Sets.Year for e ∈ Sets.Emission for se ∈ Sets.Sector
    for r ∈ Sets.Region_full
      @constraint(model,
      sum(model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ Sets.Technology if Params.TagTechnologyToSector[t,se] != 0) == model[:AnnualSectoralEmissions][y,e,se,r],
      base_name="ES1_AnnualSectorEmissions_$(y)_$(e)_$(se)_$(r)")
    end

    @constraint(model,
    sum(model[:AnnualSectoralEmissions][y,e,se,r] for r ∈ Sets.Region_full ) <= Params.AnnualSectoralEmissionLimit[e,se,y],
    base_name="ES2_AnnualSectorEmissionsLimit_$(y)_$(e)_$(se)")
  end end end

  print("Cstr: ES: ",Dates.now()-start,"\n")
   ######### Short-Term Storage Constraints #############
   start=Dates.now()

  if Switch.switch_short_term_storage == 1 #new storage formulation
    for r ∈ Sets.Region_full for s ∈ Sets.Storage for i ∈ 1:length(Sets.Year)
      if i == 1
        JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[i], r], Params.StorageLevelStart[r,s];force=true)
      else
        @constraint(model, 
        model[:StorageLevelYearStart][s,Sets.Year[i-1],r] + sum((sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
            - sum( model[:RateOfActivity][Sets.Year[i],l,t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0)) * Params.YearSplit[l,Sets.Year[i]] for l ∈ Sets.Timeslice)
        == model[:StorageLevelYearStart][s,Sets.Year[i],r],
        base_name="S1_StorageLevelYearStart_$(r)_$(s)_$(Sets.Year[i])")
        
        JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[i], r], 0;force=true)
      end
      
      @constraint(model,
      sum((sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
                - sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0)) for l ∈ Sets.Timeslice) == 0,
                base_name="S3_StorageRefilling_$(r)_$(s)_$(Sets.Year[i])")

      for j ∈ 1:length(Sets.Timeslice)
#=         @constraint(model,
        (j>1 ? model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j-1],r] +
            (sum(model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
          - sum(model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0) * Params.YearSplit[Sets.Timeslice[j-1],Sets.Year[i]]) : 0)
          + (j == 1 ? model[:StorageLevelYearStart][s,Sets.Year[i],r] : 0)   == model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
          base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])") =#

        @constraint(model,
        (j>1 ? model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j-1],r] + 
        (sum((Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0 ? model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] : 0) for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies)
          - sum((Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0 ? model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] : 0 ) for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies)) * Params.YearSplit[Sets.Timeslice[j-1],Sets.Year[i]] : 0)
          + (j == 1 ? model[:StorageLevelYearStart][s,Sets.Year[i],r] : 0)   == model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
          base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])")

        @constraint(model,
        sum(model[:NewStorageCapacity][s,Sets.Year[i],r] + Params.ResidualStorageCapacity[r,s,Sets.Year[i]] for yy ∈ Sets.Year if (Sets.Year[i]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[i]-yy >= 0))
        >= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
        base_name="SC2_UpperLimit_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)")

      end

      @constraint(model,
      Params.CapitalCostStorage[r,s,Sets.Year[i]] * model[:NewStorageCapacity][s,Sets.Year[i],r] == model[:CapitalInvestmentStorage][s,Sets.Year[i],r],
      base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(Sets.Year[i])_$(r)")
      @constraint(model,
      model[:CapitalInvestmentStorage][s,Sets.Year[i],r]/((1+Settings.GeneralDiscountRate[r])^(Sets.Year[i]-Switch.StartYear+0.5)) == model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[i],r],
      base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(Sets.Year[i])_$(r)")
      if ((Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) <= Sets.Year[end] )
        @constraint(model,
        model[:SalvageValueStorage][s,Sets.Year[i],r] == 0,
        base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(Sets.Year[i])_$(r)")
      end
      if ((Settings.DepreciationMethod[r]==1 && (Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0) || (Settings.DepreciationMethod[r]==2 && (Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0))
        @constraint(model,
        model[:CapitalInvestmentStorage][s,Sets.Year[i],r]*(1- Sets.Year[end] - Sets.Year[i]+1)/Params.OperationalLifeStorage[r,s,Sets.Year[i]] == model[:SalvageValueStorage][s,Sets.Year[i],r],
        base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(Sets.Year[i])_$(r)")
      end
      if (Settings.DepreciationMethod[r]==1 && ((Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]>0))
        @constraint(model,
        model[:CapitalInvestmentStorage][s,Sets.Year[i],r]*(1-((1+Settings.GeneralDiscountRate[r])^(Sets.Year[end] - Sets.Year[i]+1)-1)/((1+Settings.GeneralDiscountRate[r])^Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1)) == model[:SalvageValueStorage][s,Sets.Year[i],r],
        base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(Sets.Year[i])_$(r)")
      end
      @constraint(model,
      model[:SalvageValueStorage][s,Sets.Year[i],r]/((1+Settings.GeneralDiscountRate[r])^(1+max(Sets.Year...) - Switch.StartYear)) == model[:DiscountedSalvageValueStorage][s,Sets.Year[i],r],
      base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(Sets.Year[i])_$(r)")
      @constraint(model,
      model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[i],r]-model[:DiscountedSalvageValueStorage][s,Sets.Year[i],r] == model[:TotalDiscountedStorageCost][s,Sets.Year[i],r],
      base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(Sets.Year[i])_$(r)")
    end end end

    for s ∈ Sets.Storage for i ∈ 1:length(Sets.Year)
      for r ∈ Sets.Region_full 
        if Params.MinStorageCharge[r,s,Sets.Year[i]] > 0
          for j ∈ 1:length(Sets.Timeslice)
            @constraint(model, 
            Params.MinStorageCharge[r,s,Sets.Year[i]]*sum(model[:NewStorageCapacity][s,Sets.Year[i],r] + Params.ResidualStorageCapacity[r,s,Sets.Year[i]] for yy ∈ Sets.Year if (Sets.Year[i]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[i]-yy >= 0))
            <= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
            base_name="SC1_LowerLimit_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)")
          end
        end
      end

      for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation
        if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0
          for r ∈ Sets.Region_full for j ∈ 1:length(Sets.Timeslice)
            @constraint(model,
            model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j],t,m,r]/Params.TechnologyFromStorage[Sets.Year[i],m,t,s]*Params.YearSplit[Sets.Timeslice[j],Sets.Year[i]] <= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
            base_name="SC9d_StorageActivityLimit_$(s)_$(t)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)_$(m)")
          end end
        end
      end end
    end end
    print("Cstr: Storage 1 : ",Dates.now()-start,"\n")

  else #Formaulation from Osemosys

    @variable(model, NumberOfStorageUnits[Sets.Region_full,Sets.Year,Sets.Storage])
    
    ######### Storage Constraints #############
    start=Dates.now()

    for s ∈ Sets.Storage for k ∈ 1:length(Sets.Year) for r ∈ Sets.Region_full

      ######### Storage Investments #############

      @constraint(model,
      model[:AccumulatedNewStorageCapacity][s,Sets.Year[k],r]+Params.ResidualStorageCapacity[r,s,Sets.Year[k]] == model[:StorageUpperLimit][s,Sets.Year[k],r],
      base_name="SI1_StorageUpperLimit_$(s)_$(Sets.Year[k])_$(r)")
      @constraint(model,
      Params.MinStorageCharge[r,s,Sets.Year[k]]*model[:StorageUpperLimit][s,Sets.Year[k],r] == model[:StorageLowerLimit][s,Sets.Year[k],r],
      base_name="SI2_StorageLowerLimit_$(s)_$(Sets.Year[k])_$(r)")
      @constraint(model,
      sum(model[:NewStorageCapacity][s,yy,r] for yy ∈ Sets.Year if (Sets.Year[k]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[k]-yy >= 0)) == model[:AccumulatedNewStorageCapacity][s,Sets.Year[k],r],
      base_name="SI3_TotalNewStorage_$(s)_$(Sets.Year[k])_$(r)")
      @constraint(model,
      Params.CapitalCostStorage[r,s,Sets.Year[k]] * model[:NewStorageCapacity][s,Sets.Year[k],r] == model[:CapitalInvestmentStorage][s,Sets.Year[k],r],
      base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(Sets.Year[k])_$(r)")
      @constraint(model,
      model[:CapitalInvestmentStorage][s,Sets.Year[k],r]/((1+Settings.GeneralDiscountRate[r])^(Sets.Year[k]-Switch.StartYear+0.5)) == model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[k],r],
      base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(Sets.Year[k])_$(r)")
      if (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) <= Sets.Year[end]
        @constraint(model,
        0 == model[:SalvageValueStorage][s,Sets.Year[k],r],
        base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(Sets.Year[k])_$(r)")
      end
      if  (Settings.DepreciationMethod[r]==1 && (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0) || (Settings.DepreciationMethod[r]==2 && (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0)
        @constraint(model,
        model[:CapitalInvestmentStorage][s,Sets.Year[k],r]*(1- Sets.Year[end]  - Sets.Year[k]+1)/Params.OperationalLifeStorage[r,s,Sets.Year[k]] == model[:SalvageValueStorage][s,Sets.Year[k],r],
        base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(Sets.Year[k])_$(r)")
      end
      if Settings.DepreciationMethod[r]==1 && ((Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]>0)
        @constraint(model,
        model[:CapitalInvestmentStorage][s,Sets.Year[k],r]*(1-(((1+Settings.GeneralDiscountRate[r])^(Sets.Year[end] - Sets.Year[k]+1)-1)/((1+Settings.GeneralDiscountRate[r])^Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1))) == model[:SalvageValueStorage][s,Sets.Year[k],r],
        base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(Sets.Year[k])_$(r)")
      end
      @constraint(model,
      model[:SalvageValueStorage][s,Sets.Year[k],r]/((1+Settings.GeneralDiscountRate[r])^(1+max(Sets.Year...) - Switch.StartYear)) == model[:DiscountedSalvageValueStorage][s,Sets.Year[k],r],
      base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(Sets.Year[k])_$(r)")
      @constraint(model,
      model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[k],r]-model[:DiscountedSalvageValueStorage][s,Sets.Year[k],r] == model[:TotalDiscountedStorageCost][s,Sets.Year[k],r],
      base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(Sets.Year[k])_$(r)")

      ######### Storage Equations #############
      if k==1
        JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[k], r], Params.StorageLevelStart[r,s]; force=true)
      end
      if k>1
        @constraint(model,
        model[:StorageLevelYearStart][s,Sets.Year[k-1],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k-1],ls,ld,lh,r] for ls ∈ Sets.Season for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelYearStart][s,Sets.Year[k],r],
        base_name="S5_StorageLeveYearStart_$(s)_$(Sets.Year[k])_$(r)")
      end
      if k<=length(Sets.Year)-1
        @constraint(model,
        model[:StorageLevelYearStart][s,Sets.Year[k+1],r] ==  model[:StorageLevelYearFinish][s,Sets.Year[k],r],
        base_name="S7_StorageLevelYearFinish_$(s)_$(Sets.Year[k])_$(r)")
      end
      if k==length(Sets.Year)
        @constraint(model,
        model[:StorageLevelYearStart][s,Sets.Year[k],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k],ls,ld,lh,r] for ls ∈ Sets.Season for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelYearFinish][s,Sets.Year[k],r],
        base_name="S8_StorageLevelYearFinish_$(s)_$(Sets.Year[k])_$(r)")
      end

      for j ∈ 1:length(Sets.Season)
        for i ∈ 1:length(Sets.Daytype)
          for lh ∈ Sets.DailyTimeBracket

            @constraint(model,
            0 <= (model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)))-model[:StorageLowerLimit][s,Sets.Year[k],r],
            base_name="SC1_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            (model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)))-model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
            base_name="SC1_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            0 <= (i>1 ? model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]-sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lhlh,r]  for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - model[:StorageLowerLimit][s,Sets.Year[k],r],
            base_name="SC2_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            (i>1 ? model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]-sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
            base_name="SC2_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            0 <= (model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)))-model[:StorageLowerLimit][s,Sets.Year[k],r],
            base_name="SC3_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            (model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)))-model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
            base_name="SC3_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            0 <= (i>1 ? model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - model[:StorageLowerLimit][s,Sets.Year[k],r],
            base_name="SC4_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            (i>1 ? model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
            base_name="SC4_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] <= Params.StorageMaxChargeRate[r,s]*model[:StorageUpperLimit][s,Sets.Year[k],r],
            base_name="SC5_MaxChargeConstraint_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] <= Params.StorageMaxDischargeRate[r,s]*model[:StorageUpperLimit][s,Sets.Year[k],r],
            base_name="SC6_MaxDischargeConstraint_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")

            @constraint(model,
            sum(model[:RateOfActivity][Sets.Year[k],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[k],m,t,s] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice if Params.TechnologyToStorage[Sets.Year[k],m,t,s]>0) == model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
            base_name="S1_RateOfStorageCharge_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            sum(model[:RateOfActivity][Sets.Year[k],l,t,m,r] * Params.TechnologyFromStorage[Sets.Year[k],m,t,s] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice if Params.TechnologyFromStorage[Sets.Year[k],m,t,s]>0) == model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
            base_name="S2_RateOfStorageDischarge_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            sum((model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] - model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r]) * Params.YearSplit[l,Sets.Year[k]] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for l ∈ Sets.Timeslice if (Params.Conversionls[l,Sets.Season[j]]>0 && Params.Conversionld[l,Sets.Daytype[i]]>0 && Params.Conversionlh[l,lh]>0) ) == model[:NetChargeWithinYear][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
            base_name="S3_NetChargeWithinYear_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
            @constraint(model,
            (model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] - model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r]) * sum(Params.DaySplit[Sets.Year[k],l] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for l ∈ Sets.Timeslice) == model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
            base_name="S4_NetChargeWithinDay_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
          end
          if i==1
            @constraint(model,
            model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] ==  model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
            base_name="S11_StorageLevelDayTypeStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
          elseif i>1
            @constraint(model,
            model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r] + sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lh,r] * Params.DaysInDayType[Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1]] for lh ∈ Sets.DailyTimeBracket)  ==  model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
            base_name="S12_StorageLevelDayTypeStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
          end
          if j==length(Sets.Season) && i == length(Sets.Daytype)
            @constraint(model,
            model[:StorageLevelYearFinish][s,Sets.Year[k],r] == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
            base_name="S13_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
          end
          if j <= length(Sets.Season)-1 && i == length(Sets.Daytype)
            @constraint(model,
            model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j+1],r] == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
            base_name="S14_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
          end
          if j <= length(Sets.Season)-1 && i <= length(Sets.Daytype)-1
            @constraint(model,
            model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1],lh,r]  * Params.DaysInDayType[Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1]] for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
            base_name="S15_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
          end
        end
        if j == 1
          @constraint(model,
          model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] == model[:StorageLevelYearStart][s,Sets.Year[k],r],
          base_name="S9_StorageLevelSeasonStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(r)")
        else
          @constraint(model,
          model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] == model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j-1],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k],Sets.Season[j-1],ld,lh,r] for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) ,
          base_name="S10_StorageLevelSeasonStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(r)")
        end
      end
    end end end
    
    print("Cstr: Storage 4 : ",Dates.now()-start,"\n")
  end

  
   ######### Transportation Equations #############
   start=Dates.now()
  for r ∈ Sets.Region_full for y ∈ Sets.Year
    for f ∈ Subsets.TransportFuels
      if Params.SpecifiedAnnualDemand[r,f,y] != 0
        for l ∈ Sets.Timeslice for mt ∈ Sets.ModalType  
          @constraint(model,
          Params.SpecifiedAnnualDemand[r,f,y]*Params.ModalSplitByFuelAndModalType[r,f,y,mt]*Params.SpecifiedDemandProfile[r,f,l,y] == model[:DemandSplitByModalType][mt,l,r,f,y],
          base_name="T1a_SpecifiedAnnualDemandByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
        end end
      end
    
      for mt ∈ Sets.ModalType
        if sum(Params.TagTechnologyToModalType[:,:,mt]) != 0
          for l ∈ Sets.Timeslice
            @constraint(model,
            sum(Params.TagTechnologyToModalType[t,m,mt]*model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for (t,m) ∈ LoopSetOutput[(r,f,y)]) == model[:ProductionSplitByModalType][mt,l,r,f,y],
            base_name="T2_ProductionOfTechnologyByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
            @constraint(model,
            model[:ProductionSplitByModalType][mt,l,r,f,y] >= model[:DemandSplitByModalType][mt,l,r,f,y],
            base_name="T3_ModalSplitBalance_$(mt)_$(l)_$(r)_$(f)_$(y)")
          end
        end
      end
    end

    for l ∈ Sets.Timeslice 
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_SHIP_RE",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_ROAD_RE",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_RAIL_RE",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_SHIP_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_ROAD_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_RAIL_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_AIR_RE",l,r,"Mobility_Freight",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_ROAD_RE",l,r,"Mobility_Freight",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_RAIL_RE",l,r,"Mobility_Freight",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_AIR_CONV",l,r,"Mobility_Freight",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_ROAD_CONV",l,r,"Mobility_Freight",y], 0; force=true)
      JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_RAIL_CONV",l,r,"Mobility_Freight",y], 0; force=true)
    end
  end end

  print("Cstr: transport: ",Dates.now()-start,"\n")
  if Switch.switch_ramping == 1
  
    ############### Ramping #############
    start=Dates.now()
    for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
      for f ∈ Sets.Fuel
        for i ∈ 1:length(Sets.Timeslice)
          if i>1
            if Params.TagDispatchableTechnology[t]==1 && (Params.RampingUpFactor[r,t,y] != 0 || Params.RampingDownFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
              @constraint(model,
              ((sum(model[:RateOfActivity][y,Sets.Timeslice[i],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0)*Params.YearSplit[Sets.Timeslice[i],y]) - (sum(model[:RateOfActivity][y,Sets.Timeslice[i-1],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0)*Params.YearSplit[Sets.Timeslice[i-1],y]))
              == model[:ProductionUpChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] - model[:ProductionDownChangeInTimeslice][y,Sets.Timeslice[i],f,t,r],
              base_name="R1_ProductionChange_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
            end
            if Params.TagDispatchableTechnology[t]==1 && Params.RampingUpFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
              @constraint(model,
              model[:ProductionUpChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] <= model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.RampingUpFactor[r,t,y]*Params.YearSplit[Sets.Timeslice[i],y],
              base_name="R2_RampingUpLimit_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
            end
            if Params.TagDispatchableTechnology[t]==1 && Params.RampingDownFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
              @constraint(model,
              model[:ProductionDownChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] <= model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.RampingDownFactor[r,t,y]*Params.YearSplit[Sets.Timeslice[i],y],
              base_name="R3_RampingDownLimit_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
            end
          end
          ############### Min Runing Constraint #############
          if Params.MinActiveProductionPerTimeslice[y,Sets.Timeslice[i],f,t,r] > 0
            @constraint(model,
            sum(model[:RateOfActivity][y,Sets.Timeslice[i],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0) >= 
            model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.MinActiveProductionPerTimeslice[y,Sets.Timeslice[i],f,t,r],
            base_name="MRC1_MinRunningConstraint_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
          end
        end

        ############### Ramping Costs #############
        if Params.TagDispatchableTechnology[t]==1 && Params.ProductionChangeCost[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
          @constraint(model,
          sum((model[:ProductionUpChangeInTimeslice][y,l,f,t,r] + model[:ProductionDownChangeInTimeslice][y,l,f,t,r])*Params.ProductionChangeCost[r,t,y] for l ∈ Sets.Timeslice) == model[:AnnualProductionChangeCost][y,t,r],
          base_name="RC1_AnnualProductionChangeCosts_$(y)_$(f)_$(t)_$(r)")
        end
        if Params.TagDispatchableTechnology[t]==1 && Params.ProductionChangeCost[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
          @constraint(model,
          model[:AnnualProductionChangeCost][y,t,r]/((1+Settings.TechnologyDiscountRate[r,t])^(y-Switch.StartYear+0.5)) == Discountedmodel[:AnnualProductionChangeCost][y,t,r],
          base_name="RC2_DiscountedAnnualProductionChangeCost_$(y)_$(f)_$(t)_$(r)")
        end
      end
      if (Params.TagDispatchableTechnology[t] == 0 || sum((m,f), Params.OutputActivityRatio[r,t,f,m,y]) == 0 || Params.ProductionChangeCost[r,t,y] == 0 || Params.AvailabilityFactor[r,t,y] == 0 || Params.TotalAnnualMaxCapacity[r,t,y] == 0 || Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 0)
        JuMP.fix(model[:DiscountedAnnualProductionChangeCost][y,t,r], 0; force=true)
        JuMP.fix(model[:AnnualProductionChangeCost][y,t,r], 0; force=true)
      end
    end end end
    
  print("Cstr: Ramping : ",Dates.now()-start,"\n")
  end

   ############### Curtailment Costs #############
  start=Dates.now()
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
    @constraint(model,
    sum(model[:Curtailment][y,l,f,r]*Params.CurtailmentCostFactor[r,f,y] for l ∈ Sets.Timeslice ) == model[:AnnualCurtailmentCost][y,f,r],
    base_name="CC1_AnnualCurtailmentCosts_$(y)_$(f)_$(r)")
    @constraint(model,
    model[:AnnualCurtailmentCost][y,f,r]/((1+Settings.GeneralDiscountRate[r])^(y-Switch.StartYear+0.5)) == model[:DiscountedAnnualCurtailmentCost][y,f,r],
    base_name="CC2_DiscountedAnnualCurtailmentCosts_$(y)_$(f)_$(r)")
  end end end

  print("Cstr: Curtailment : ",Dates.now()-start,"\n")

  if Switch.switch_base_year_bounds == 1
  
   ############### General BaseYear Limits && trajectories #############
   start=Dates.now()
    for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
      for f ∈ Sets.Fuel
        if Params.RegionalBaseYearProduction[r,t,f,y] != 0
          @constraint(model,
          model[:ProductionByTechnologyAnnual][y,t,f,r] >= Params.RegionalBaseYearProduction[r,t,f,y]*(1-model[:BaseYearSlack][f]) - model[:RegionalBaseYearProduction_neg][y,r,t,f],
          base_name="B4a_RegionalBaseYearProductionLowerBound_$(y)_$(r)_$(t)_$(f)")
        end
      end
      if Params.RegionalBaseYearProduction[r,t,"Power",y] != 0
        @constraint(model,
        model[:ProductionByTechnologyAnnual][y,t,"Power",r] <= Params.RegionalBaseYearProduction[r,t,"Power",y]+model[:BaseYearOvershoot][r,t,"Power",y],
        base_name="B4b_RegionalBaseYearProductionUpperBound_$(y)_$(r)_$(t)_Power")
      end
    end end end
    print("Cstr: Baseyear : ",Dates.now()-start,"\n")
  end
  
   ######### Peaking Equations #############
   start=Dates.now()
  if Switch.switch_peaking_capacity == 1
    @variable(model, PeakingDemand[Sets.Year,Sets.Region_full])
    @variable(model, PeakingCapacity[Sets.Year,Sets.Region_full])
    GWh_to_PJ = 0.0036
    PeakingSlack = Switch.set_peaking_slack
    MinRunShare = Switch.set_peaking_minrun_share
    RenewableCapacityFactorReduction = Switch.set_peaking_res_cf
    for y ∈ Sets.Year for r ∈ Sets.Region_full
      @constraint(model,
      model[:PeakingDemand][y,r] ==
        sum(model[:UseByTechnologyAnnual][y,t,"Power",r]/GWh_to_PJ*Params.x_peakingDemand[r,se]/8760
          #Demand per Year in PJ             to Gwh     Highest peak hour value   /number hours per year
        for se ∈ Sets.Sector for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if Params.x_peakingDemand[r,se] != 0 && Params.TagTechnologyToSector[t,se] != 0)
      + Params.SpecifiedAnnualDemand[r,"Power",y]/GWh_to_PJ*Params.x_peakingDemand[r,"Power"]/8760,
      base_name="PC1_PowerPeakingDemand_$(y)_$(r)")

      @constraint(model,
      model[:PeakingCapacity][y,r] ==
        sum((sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice ) < length(Sets.Timeslice) ? model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*RenewableCapacityFactorReduction*(sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice)/length(Sets.Timeslice)) : 0)
        + (sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice ) >= length(Sets.Timeslice) ? model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y] : 0)
        for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if (sum(Params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ Sets.Mode_of_operation) != 0)),
        base_name="PC2_PowerPeakingCapacity_$(y)_$(r)")

      if y >Switch.set_peaking_startyear
        @constraint(model,
        model[:PeakingCapacity][y,r] + (Switch.switch_peaking_with_trade == 1 ? sum(model[:TotalTradeCapacity][y,"Power",rr,r] for rr ∈ Sets.Region_full) : 0)
        + (Switch.switch_peaking_with_storages == 1 ? sum(model[:TotalCapacityAnnual][y,t,r] for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if (sum(Params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ Sets.Mode_of_operation) != 0)) : 0)
        >= model[:PeakingDemand][y,r]*PeakingSlack,
        base_name="PC3_PeakingConstraint_$(y)_$(r)")
      end
      
      if Switch.switch_peaking_minrun == 1
        for t ∈ Sets.Technology
          if (Params.TagTechnologyToSector[t,"Power"]==1 && Params.AvailabilityFactor[r,t,y]<=1 && 
            Params.TagDispatchableTechnology[t]==1 && Params.AvailabilityFactor[r,t,y] > 0 && 
            Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 && 
            ((((JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][y,t,r]) > 0)) ||
            ((!JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (!JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]))) ||
            ((JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) > 0)))) && 
            y > Switch.set_peaking_startyear)
            @constraint(model,
            sum(sum(model[:RateOfActivity][y,l,t,m,r] for m ∈ Sets.Mode_of_operation)*Params.YearSplit[l,y] for l ∈ Sets.Timeslice ) >= 
            sum(model[:TotalCapacityAnnual][y,t,r]*Params.CapacityFactor[r,t,l,y]*Params.YearSplit[l,y]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t] for l ∈ Sets.Timeslice )*MinRunShare,
            base_name="PC4_MinRunConstraint_$(y)_$(t)_$(r)")
          end
        end
      end
    end end
  end
  print("Cstr: Peaking : ",Dates.now()-start,"\n")


  if Switch.switch_endogenous_employment == 1

   ############### Employment effects #############
  
    @variable(model, TotalJobs[Sets.Region_full, Sets.Year])

    genesysmod_employment(model,Params,Emp_Sets)
    for r ∈ Sets.Region_full for y ∈ Sets.Year
      @constraint(model,
      sum(((model[:NewCapacity][y,t,r]*Emp_Params.EFactorManufacturing[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y]*Emp_Params.LocalManufacturingFactor[Switch.model_region,y])
      +(model[:NewCapacity][y,t,r]*Emp_Params.EFactorConstruction[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y])
      +(model[:TotalCapacityAnnual][y,t,r]*Emp_Params.EFactorOM[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y])
      +(model[:UseByTechnologyAnnual][y,t,f,r]*Emp_Params.EFactorFuelSupply[t,y]))*(1-Emp_Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Sets)
      +((model[:UseByTechnologyAnnual][y,"HLI_Hardcoal","Hardcoal",r]+model[:UseByTechnologyAnnual][y,"HMI_HardCoal","Hardcoal",r]
      +(model[:UseByTechnologyAnnual][y,"HHI_BF_BOF","Hardcoal",r])*Emp_Params.EFactorCoalJobs["Coal_Heat",y]*Emp_Params.CoalSupply[r,y]))
      +(Emp_Params.CoalSupply[r,y]*Emp_Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*Emp_Params.EFactorCoalJobs["Coal_Export",y]) for t ∈ Sets.Technology for f ∈ Sets.Fuel)
      == model[:TotalJobs][r,y],
      base_name="Jobs1_TotalJobs_$(r)_$(y)")
    end end
  end
end