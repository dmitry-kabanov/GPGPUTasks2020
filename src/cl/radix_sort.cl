#ifdef __CLION_IDE__
#include <libgpu/opencl/cl/clion_defines.cl>
#endif

#line 6

#ifndef WORK_GROUP_SIZE
#define WORK_GROUP_SIZE 128
#endif

// See https://github.com/GPGPUCourse/GPGPUTasks2020/pull/214

__kernel void tree_sum(__global unsigned int* as, __global unsigned int* work_group_sum, const unsigned int n, const unsigned int bit)
{
    const unsigned int local_id = get_local_id(0);
    const unsigned int group_id = get_group_id(0);
    const unsigned int global_id = get_global_id(0);

    __local unsigned int local_array[WORK_GROUP_SIZE];
    if (global_id < n) {
        local_array[local_id] = 1 - (as[global_id] >> bit) & 1;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    for (unsigned int nvalues = WORK_GROUP_SIZE; nvalues > 1; nvalues /= 2) {
        if (2 * local_id < nvalues) {
            unsigned a = local_array[local_id];
            unsigned b = local_array[local_id + nvalues / 2];
            local_array[local_id] = a + b;
        }

        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (local_id == 0) {
        work_group_sum[group_id] = local_array[0];
    }
}

__kernel void get_inverse_bit(__global unsigned int* as, __global unsigned int* bit_array, const unsigned int n, const unsigned int bit) {
    const unsigned int global_id = get_global_id(0);
    if (global_id < n)
        bit_array[global_id] = 1 - (as[global_id] >> bit) & 1;
}

__kernel void prefix_sum(__global unsigned int* partial_sum, __global unsigned int* prefix_sum, const unsigned int n, const unsigned int pow) {
    const unsigned int global_id = get_global_id(0);
    if (global_id < n) {
        if (((global_id + 1) >> pow) & 1)
            prefix_sum[global_id] += partial_sum[(global_id + 1) / (1 << pow) - 1];
    }
}

__kernel void partial_sum(__global unsigned int* cur_partial_sum, __global unsigned int* next_partial_sum, const unsigned int n) {
    const unsigned int global_id = get_global_id(0);
    if (global_id < n)
        next_partial_sum[global_id] = cur_partial_sum[2 * global_id] + cur_partial_sum[2 * global_id + 1];
}

__kernel void radix(__global unsigned int* cur_as, __global unsigned int* next_as, __global unsigned int* prefix_sum, const unsigned int n, const unsigned int bit) {
    const unsigned int global_id = get_global_id(0);
    if (global_id < n) {
        if (1 - (cur_as[global_id] >> bit) & 1)
            next_as[prefix_sum[global_id] - 1] = cur_as[global_id];
        else
            next_as[prefix_sum[n - 1] + global_id - prefix_sum[global_id]] = cur_as[global_id];
    }
}


//надо как то по умному научиться считать префиксы до начал ворк групп
__kernel void local_radix(__global unsigned int* cur_as, __global unsigned int* next_as, __global unsigned int* work_group_prefix_sum, const unsigned int n, const unsigned int bit) {
    __local unsigned int local_array[WORK_GROUP_SIZE];
    __local unsigned int local_prefix_sum[WORK_GROUP_SIZE];
    __local unsigned int value_of_prefix_sum;

    const unsigned int global_id = get_global_id(0);
    const unsigned int group_id = get_group_id(0);
    const unsigned int local_id = get_local_id(0);

    if (local_id == 0 ){
        if (group_id > 0)
            value_of_prefix_sum = work_group_prefix_sum[group_id - 1];
        else
            value_of_prefix_sum = 0;
    }

    if (global_id < n) {
        local_array[local_id] = 1 - (cur_as[global_id] >> bit) & 1;
    }

    for (int pow = 0; pow < log2((float) WORK_GROUP_SIZE) + 1; ++pow) {

        barrier(CLK_LOCAL_MEM_FENCE);

        if (global_id < n) {
            if (((local_id + 1) >> pow) & 1) {
                local_prefix_sum[local_id] += local_array[(local_id + 1) / (1 << pow) - 1];
            }
        }

        barrier(CLK_LOCAL_MEM_FENCE);

        if (local_id % 2 == 0)
            local_array[local_id / 2] = local_array[local_id] + local_array[local_id + 1];
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    if (global_id < n) {
        if (1 - (cur_as[global_id] >> bit) & 1)
            next_as[local_prefix_sum[local_id] + value_of_prefix_sum - 1] = cur_as[global_id];
        else
            next_as[work_group_prefix_sum[(n + WORK_GROUP_SIZE - 1) / WORK_GROUP_SIZE - 1] + global_id -
                    local_prefix_sum[local_id] - value_of_prefix_sum] = cur_as[global_id];
    }
}
