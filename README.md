В этом репозитории предложены задания для [курса по вычислениям на видеокартах в CSC](https://compscicenter.ru/courses/video_cards_computation/2020-autumn/).

[Остальные задания](https://github.com/GPGPUCourse/GPGPUTasks2020/).

# Пример OpenCL <-> CUDA

[![Build Status](https://travis-ci.com/GPGPUCourse/GPGPUTasks2020.svg?branch=cuda)](https://travis-ci.com/GPGPUCourse/GPGPUTasks2020)

Этот проект иллюстрирует как написать код для видеокарты посредством OpenCL и затем скомпилировать его в т.ч. для исполнения через CUDA. Это дает замечательную возможность использовать тулинг CUDA:

 - профилировщик (**computeprof** - он же **nvvp**, или более новый - **NsightCompute**): позволяет посмотреть timeline выполнения кернелов, операций по копированию видеопамяти, насколько какой кернел насытил пропускную способность видеопамяти/локальной памяти или ALU, число используемых регистров и локальной памяти (и соответственно насколько высока occupancy)

 - **cuda-memcheck** позволяет проверить что нет out-of-bounds обращений к памяти (если есть - укажет проблемную строку в кернеле)
 
 - **cuda-memcheck --tool racecheck** позволяет проверить что нет гонок между потоками рабочей группы при обращении к локальной памяти (т.е. что нигде не забыты барьеры). Если гонка есть - укажет на ее характер (RAW/WAR/WAW) и на строки в кернеле (обеих операций участвующих в гонке)

# Ориентиры

Здесь предложены две задачи - простое C=A+B и Radix Sort из [PR#214](https://github.com/GPGPUCourse/GPGPUTasks2020/pull/214).

В целом достаточно посмотреть на последние коммиты в этой ветке. Особенно на коммит [Translated to CUDA](https://github.com/GPGPUCourse/GPGPUTasks2020/commit/828416ce0b6504cb687a973c0882ce85cb40d396) и [Radix Sort translated to CUDA](https://github.com/GPGPUCourse/GPGPUTasks2020/commit/4a287320806109ba9fb49f73065b2801765a7890).

Но вот дополнительные ориентиры:

 - [CMakeLists.txt](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/cuda/CMakeLists.txt#L28-L32): Поиск CUDA-компилятора, добавление для NVCC компилятора флажка 'сохранять номера строк' (нужно чтобы cuda-memcheck мог указывать номера строк с ошибками), добавление ```src/cu/aplusb.cu``` в список исходников, компиляция через ```cuda_add_executable```.
 - [aplusb.cu](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/cuda/src/cu/aplusb.cu): CUDA-кернел транслируется из OpenCL-кернела посредством [макросов](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/cuda/libs/gpu/libgpu/cuda/cu/opencl_translator.cu), вызов кернела через функцию ```cuda_aplusb```
 - **main_aplusb.cpp**: [декларация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L28-L30) функции ```cuda_aplusb```, [инициализация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L59) CUDA-контекста, [вызов](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L111) функции вызывающий кернел
 - [radix_sort.cu](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/cuda/src/cu/radix_sort.cu): четыре CUDA-кернела транслируются из OpenCL-версий посредством макросов
 - **main_radix.cpp**: [декларация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/4a287320806109ba9fb49f73065b2801765a7890/src/main_radix.cpp#L26-L46) четырех кернелов, [инициализация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/4a287320806109ba9fb49f73065b2801765a7890/src/main_radix.cpp#L58) CUDA-контекста, [вызов](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/cuda/src/main_radix.cpp#L128) одного из кернелов
