"""
    This file contains the functions to benchmark the models using OptimalControl
"""

# Function to solve the model
function solving_model_OC(model,nb_discr,init;max_iter=1000, tol=1e-8, constr_viol_tol = 1e-6,solver="ma57",display=false)
    # Solve the problem
    if solver == "ma57"
        t =  @timed ( 
            sol = OptimalControl.solve(model, grid_size=nb_discr, init=init, 
                linear_solver="ma57",hsllib=HSL_jll.libhsl_path,
                max_iter=max_iter, tol=tol, constr_viol_tol = constr_viol_tol, 
                display=display, sb = "yes",output_file="./outputs/outputOC.out",
                print_level=0,
                );
            )
    elseif solver == "ma27"
        t =  @timed ( 
            sol = OptimalControl.solve(model, grid_size=nb_discr, init=init, 
                linear_solver="ma27",hsllib=HSL_jll.libhsl_path,
                max_iter=max_iter, tol=tol, constr_viol_tol = constr_viol_tol, 
                display=display, sb = "yes",output_file="./outputs/outputOC.out",
                print_level=0,
                );
            )
    elseif solver == "mumps"
        t =  @timed ( 
            sol = OptimalControl.solve(model, grid_size=nb_discr, init=init, 
                max_iter=max_iter, tol=tol, constr_viol_tol = constr_viol_tol, 
                display=display, sb = "yes",output_file="./outputs/outputOC.out",
                print_level=0,
                );
            )
    else
        error("The solver $solver is not supported")
    end
    # Get the results
    outputOC = read("./outputs/outputOC.out", String)
    tIpopt = parse(Float64,split(split(outputOC, "Total seconds in IPOPT                               =")[2], "\n")[1])
    obj_value = sol.objective
    flag = sol.message
    nb_iter = sol.iterations
    Ipopt_time = tIpopt
    total_time = t.time
    nlp = direct_transcription(model; grid_size=nb_discr)[2]
    nvar = nlp.meta.nvar
    ncon = nlp.meta.ncon
    return nb_iter, total_time, Ipopt_time, obj_value, flag, nvar, ncon
end


# Function to benchmark the model
function benchmark_model_OC(model_function,model_init, nb_discr_list;max_iter=1000, tol=1e-8, constr_viol_tol = 1e-6,solver="ma57",display=false)
    DataModel = []
    # Loop over the list of number of discretization
    for nb_discr in nb_discr_list
        model = model_function()
        # Solve the model
        nb_iter, total_time, Ipopt_time, obj_value, flag, nvar, ncon = solving_model_OC(model,nb_discr,model_init(;nh=nb_discr);max_iter=max_iter, tol=tol, constr_viol_tol = constr_viol_tol,solver=solver,display=display)
        # Save the data
        data = DataFrame(:nb_discr => nb_discr,
                        :nvar => nvar,
                        :ncon => ncon,
                        :nb_iter => nb_iter,
                        :obj_value => obj_value,
                        :total_time => total_time,
                        :Ipopt_time => Ipopt_time,
                        :flag => flag)
        push!(DataModel,data)
    end
    return DataModel
end


# Function to benchmark all the models
function benchmark_all_models_OC(models, inits , nb_discr_list, excluded_models;max_iter=1000, tol=1e-8, constr_viol_tol = 1e-6,solver="ma57",display=false)
    Results = Dict{Symbol,Any}()
    for (k,v) in models
        print("Benchmarking the model ",k, " ... ")
        if k in excluded_models
            Results[k] = []
            println("❌")
            continue
        end
        info = benchmark_model_OC(v,inits[k], nb_discr_list;max_iter=max_iter, tol=tol, constr_viol_tol = constr_viol_tol,solver=solver,display=display)
        Results[k] = info
        println("✅")
    end
    return Results
end


