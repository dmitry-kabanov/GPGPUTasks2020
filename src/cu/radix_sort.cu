#include <libgpu/cuda/cu/opencl_translator.cu>

#include "../cl/radix_sort.cl"

void cuda_get_inverse_bit(const gpu::WorkSize &workSize,
                          unsigned int* as, unsigned int* bit_array, const unsigned int n, const unsigned int bit,
                          cudaStream_t stream)
{
    get_inverse_bit<<<workSize.cuGridSize(), workSize.cuBlockSize(), 0, stream>>>(as, bit_array, n, bit);
    CUDA_CHECK_KERNEL(stream);
}

void cuda_prefix_sum(const gpu::WorkSize &workSize,
                     unsigned int* partial_sum, unsigned int* prefix_sum_ptr, const unsigned int n, const unsigned int pow,
                     cudaStream_t stream)
{
    prefix_sum<<<workSize.cuGridSize(), workSize.cuBlockSize(), 0, stream>>>(partial_sum, prefix_sum_ptr, n, pow);
    CUDA_CHECK_KERNEL(stream);
}

void cuda_partial_sum(const gpu::WorkSize &workSize,
                      unsigned int* cur_partial_sum, unsigned int* next_partial_sum, const unsigned int n,
                      cudaStream_t stream)
{
    partial_sum<<<workSize.cuGridSize(), workSize.cuBlockSize(), 0, stream>>>(cur_partial_sum, next_partial_sum, n);
    CUDA_CHECK_KERNEL(stream);
}

void cuda_radix(const gpu::WorkSize &workSize,
                unsigned int* cur_as, unsigned int* next_as, unsigned int* prefix_sum, const unsigned int n, const unsigned int bit,
                cudaStream_t stream)
{
    radix<<<workSize.cuGridSize(), workSize.cuBlockSize(), 0, stream>>>(cur_as, next_as, prefix_sum, n, bit);
    CUDA_CHECK_KERNEL(stream);
}
