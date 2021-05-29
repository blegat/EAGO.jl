# Copyright (c) 2018: Matthew Wilhelm & Matthew Stuber.
# This code is licensed under MIT license (see LICENSE.md for full details)
#############################################################################
# EAGO
# A development environment for robust and global optimization
# See https://github.com/PSORLab/EAGO.jl
#############################################################################
# src/eago_optimizer/display.jl
# Functions used to print information about solution routine to console.
# Printing is done with reference to the input problem is there is any
# ambiguity.
#############################################################################

const PRINTING_IOFORMAT = :SCI
const PRINTING_CHARSET = :ASCII

"""
$(FUNCTIONNAME)

Prints solution information for the B&B problem. Displays first node found, solution value,
solution, and time spent solving subproblems.
"""
function print_solution!(m::Optimizer)
    if m._parameters.verbosity > 0
        println(" ")
        if m._end_state == GS_OPTIMAL
            println("Empty Stack: Exhaustive Search Finished")
        elseif m._end_state == GS_INFEASIBLE
            println("Empty Stack: Infeasible")
        elseif m._end_state == GS_NODE_LIMIT
            println("Node Limit Exceeded")
        elseif m._end_state == GS_ITERATION_LIMIT
            println("Maximum Iteration Exceeded")
        elseif m._end_state == GS_RELATIVE_TOL
            println("Relative Tolerance Achieved")
        elseif m._end_state == GS_ABSOLUTE_TOL
            println("Absolute Tolerance Achieved")
        elseif m._end_state == GS_TIME_LIMIT
            println("Time Limit Exceeded")
        end
        println("First Solution Found at Node $(m._first_solution_node)")
        if (m._input_problem._optimization_sense !== MOI.MIN_SENSE)
            println("LBD = $(MOI.get(m, MOI.ObjectiveValue()))")
            println("UBD = $(MOI.get(m, MOI.ObjectiveBound()))")
        else
            println("LBD = $(MOI.get(m, MOI.ObjectiveBound()))")
            println("UBD = $(MOI.get(m, MOI.ObjectiveValue()))")
        end
        println("Solution is :")
        if m._feasible_solution_found
            k = _obj_var_slack_added(m) ? 1 : 0
            for i = 1:(m._input_problem._variable_count - k)
                println("    X[$i] = $(m._continuous_solution[i])")
            end
        end
        println(" ")
     end
     return
end

"""
$(FUNCTIONNAME)

Prints node information for the B&B problem. Node id, bound, and interval box.
"""
function print_node!(m::Optimizer)
    n = m._current_node
    bound = (m._input_problem._optimization_sense === MOI.MIN_SENSE) ? n.lower_bound : -n.lower_bound
    k = length(n) - (_obj_var_slack_added(m) ? 1 : 0)
    println(" ")
    println("Node ID: $(n.id), Lower Bound: $(bound), Lower Variable Bounds:
             $(n.lower_variable_bounds[1:k]), Upper Variable Bounds: $(n.upper_variable_bounds[1:k])")
    println(" ")
    return
end

"""
$(FUNCTIONNAME)

Prints the iteration information based on verbosity. The header is displayed
every `header_interval`, the iteration info is displayed every `iteration_interval`.
"""
function print_iteration!(m::Optimizer)

    if m._parameters.verbosity > 0

        if m._input_problem._optimization_sense === MOI.MAX_SENSE && m._iteration_count === 1
            println(" ")
            println("For maximization problems a max(f) = -min(-f) transformation is applied.")
            println("Objectives values for each subproblem as a negative value of the objective")
            println("in the original problem and reconciled after branch and bound terminates.")
            println(" ")
        end

        # prints header line every B.hdr_intv times
        if mod(m._iteration_count, m._parameters.header_iterations) === 0 || m._iteration_count === 1
            println("-----------------------------------------------------------------------------------------------------------------------------")
            println("|  Iteration #  |     Nodes    | Lower Bound  |  Upper Bound  |      Gap     |     Ratio    |     Time     |    Time Left   |")
            println("-----------------------------------------------------------------------------------------------------------------------------")
        end

        # prints iteration summary every B.itr_intv times
        if mod(m._iteration_count, m._parameters.output_iterations) === 0

            print_str = "| "

            max_len = 12
            temp_str = string(m._iteration_count)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*"  | "

            max_len = 12
            temp_str = string(m._node_count)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*" | "

            max_len = 12
            if m._input_problem._optimization_sense === MOI.MIN_SENSE
                lower = m._global_lower_bound
                upper = m._global_upper_bound
            else
                lower = -m._global_upper_bound
                upper = -m._global_lower_bound
            end
            #temp_str = string(round(lower, sigdigits = 5))
            #temp_str = string(lower, sigdigits = 3))
            temp_str = formatted(lower, PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*" | "

            #temp_str = formatted(upper, PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            #temp_str = string(upper, sigdigits = 3))
            temp_str = formatted(upper, PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*"  |"

            max_len = 12
            #temp_str = string(round(abs(x._global_upper_bound - x._global_lower_bound), sigdigits = 3))
            temp_str = formatted(abs(m._global_upper_bound - m._global_lower_bound), PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*"  | "

            max_len = 12
            #temp_str = string(round(relative_gap(x._global_lower_bound, x._global_upper_bound), sigdigits = 3))
            temp_str = formatted(relative_gap(m._global_lower_bound, m._global_upper_bound), PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*" | "

            max_len = 12
            #temp_str = string(round(x._run_time, sigdigits = 3))
            temp_str = formatted(m._run_time, PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*" |  "

            max_len = 12
            #temp_str = string(round(x._time_left, sigdigits = 4))
            temp_str = formatted(m._time_left, PRINTING_IOFORMAT, ndigits=4, charset=PRINTING_CHARSET)
            len_str = length(temp_str)
            print_str *= (" "^(max_len - len_str))*temp_str*"  |"

            println(print_str)
        end
    end

    return
end

"""
$(FUNCTIONNAME)

Prints the results of a single bounding problem.
"""
function print_results!(m::Optimizer, flag::Bool)
    if m._parameters.verbosity > 1
        k = length(m._lower_solution) - (_obj_var_slack_added(m) ? 1 : 0)
        println(" ")
        if flag
            if m._input_problem._optimization_sense === MOI.MIN_SENSE
                print("Lower Bound (First Iteration): $(m._lower_objective_value),")
            else
                print("Upper Bound (First Iteration): $(m._lower_objective_value),")
            end
            print(" Solution: $(m._lower_solution[1:k]), Feasibility: $(m._lower_feasibility)\n")
            println("Termination Status Code: $(m._lower_termination_status)")
            println("Result Code: $(m._lower_primal_status)")
        else
            if m._input_problem._optimization_sense === MOI.MIN_SENSE
                print("Upper Bound: $(m._upper_objective_value), ")
            else
                print("Lower Bound: $(m._upper_objective_value), ")
            end
            print(" Solution: $(m._upper_solution[1:k]), Feasibility: $(m._upper_feasibility)\n")
            println("Termination Status Code: $(m._upper_termination_status)")
            println("Result Code: $(m._upper_result_status)")
        end
    end
    return
end
