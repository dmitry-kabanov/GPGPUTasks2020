#include <libutils/misc.h>
#include <libutils/timer.h>
#include <libutils/fast_random.h>
#include <libgpu/context.h>
#include <libgpu/shared_device_buffer.h>

// Этот файл будет сгенерирован автоматически в момент сборки - см. convertIntoHeader в CMakeLists.txt:18
#include "cl/radix_cl.h"

#include <vector>
#include <iostream>
#include <stdexcept>


template<typename T>
void raiseFail(const T &a, const T &b, std::string message, std::string filename, int line)
{
    if (a != b) {
        std::cerr << message << " But " << a << " != " << b << ", " << filename << ":" << line << std::endl;
        throw std::runtime_error(message);
    }
}

#define EXPECT_THE_SAME(a, b, message) raiseFail(a, b, message, __FILE__, __LINE__)

// See https://github.com/GPGPUCourse/GPGPUTasks2020/pull/214

int main(int argc, char **argv)
{
    gpu::Device device = gpu::chooseGPUDevice(argc, argv);

    gpu::Context context;
    context.init(device.device_id_opencl);
    context.activate();

    int benchmarkingIters = 3;
    unsigned int n = 32 * 1024 * 1024;
    std::vector<unsigned int> as(n, 0);
    FastRandom r(n);
    for (unsigned int i = 0; i < n; ++i) {
        as[i] = (unsigned int) r.next(0, std::numeric_limits<int>::max());
    }
    std::cout << "Data generated for n=" << n << "!" << std::endl;

    std::vector<unsigned int> cpu_sorted;
    {
        timer t;
        for (int iter = 0; iter < benchmarkingIters; ++iter) {
            cpu_sorted = as;
            std::sort(cpu_sorted.begin(), cpu_sorted.end());
            t.nextLap();
        }
        std::cout << "CPU: " << t.lapAvg() << "+-" << t.lapStd() << " s" << std::endl;
        std::cout << "CPU: " << (n/1000/1000) / t.lapAvg() << " millions/s" << std::endl;
    }

    std::vector<unsigned int> gpu_sorted;

    {
        gpu_sorted = as;

        ocl::Kernel get_inverse_bit(radix_kernel, radix_kernel_length, "get_inverse_bit");
        get_inverse_bit.compile();
        ocl::Kernel prefix_sum_kernel(radix_kernel, radix_kernel_length, "prefix_sum");
        prefix_sum_kernel.compile();
        ocl::Kernel partial_sum_kernel(radix_kernel, radix_kernel_length, "partial_sum");
        partial_sum_kernel.compile();
        ocl::Kernel radix(radix_kernel, radix_kernel_length, "radix");
        radix.compile();

        unsigned int workGroupSize = 128;
        unsigned int global_work_size = (n + workGroupSize - 1) / workGroupSize * workGroupSize;

        timer t;

        gpu::gpu_mem_32u cur_as, next_as, prefix_sum, initial_prefix_sum, cur_partial_sum, next_partial_sum;
        cur_as.resizeN(n);
        next_as.resizeN(n);
        prefix_sum.resizeN(n);
        cur_partial_sum.resizeN(n);
        next_partial_sum.resizeN(n);
        //можно ли как то покрасивее это делать?
        std::vector<unsigned int> zeros_array(n, 0);
        initial_prefix_sum.resizeN(n);

        for (int iter = 0; iter < benchmarkingIters; ++iter) {
            cur_as.writeN(as.data(), n);
            initial_prefix_sum.writeN(zeros_array.data(), n);
            t.restart(); // Запускаем секундомер после прогрузки данных чтобы замерять время работы кернела, а не трансфер данных
            for(unsigned int bit = 0; bit <= std::log2(std::numeric_limits<int>::max())+1; ++bit) {
                get_inverse_bit.exec(gpu::WorkSize(workGroupSize, global_work_size), cur_as, cur_partial_sum, n, bit);
                initial_prefix_sum.copyToN(prefix_sum, n);
                unsigned int cur_size = global_work_size;
                for (unsigned int pow = 0; pow <= std::log2(n); ++pow) {
                    prefix_sum_kernel.exec(gpu::WorkSize(workGroupSize, global_work_size), cur_partial_sum, prefix_sum, n, pow);
                    cur_size /= 2;
                    partial_sum_kernel.exec(gpu::WorkSize(workGroupSize, std::max(cur_size, workGroupSize)), cur_partial_sum, next_partial_sum, cur_size);
                    next_partial_sum.copyToN(cur_partial_sum, cur_size);
                }
                radix.exec(gpu::WorkSize(workGroupSize, global_work_size), cur_as, next_as, prefix_sum, n, bit);
                t.nextLap();
                next_as.copyToN(cur_as, n);
            }
        }
        std::cout << "GPU: " << t.lapAvg() << "+-" << t.lapStd() << " s" << std::endl;
        std::cout << "GPU: " << (n/1000/1000) / t.lapAvg() << " millions/s" << std::endl;

        cur_as.readN(gpu_sorted.data(), n);
    }

    for (int i = 0; i < n; ++i) {
        EXPECT_THE_SAME(gpu_sorted[i], cpu_sorted[i], "GPU results should be equal to CPU results!");
    }

    return 0;
}
