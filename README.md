В этом репозитории предложены задания для [курса по вычислениям на видеокартах в CSC](https://compscicenter.ru/courses/video_cards_computation/2020-autumn/).

[Остальные задания](https://github.com/GPGPUCourse/GPGPUTasks2020/).

# Пример OpenCL <-> CUDA

[![Build Status](https://travis-ci.com/GPGPUCourse/GPGPUTasks2020.svg?branch=cuda)](https://travis-ci.com/GPGPUCourse/GPGPUTasks2020)

Этот проект иллюстрирует как написав код для видеокарты один раз на OpenCL - скомпилировать его в т.ч. для исполнения через CUDA. Это дает замечательную возможность использовать тулинг CUDA:

 - профилировщик (**computeprof** - он же **nvvp**, или более новый - **NsightCompute**): позволяет посмотреть timeline выполнения кернелов, операций по копированию видеопамяти, насколько какой кернел насытил пропускную способность видеопамяти/локальной памяти или ALU, насколько высока occupancy

 - **cuda-memcheck** позволяет проверить что нет out-of-bounds обращений к памяти (если есть - укажет проблемную строку в кернеле)
 
 - **cuda-memcheck --tool racecheck** позволяет проверить что нет гонок между потоками рабочей группы при обращении к локальной памяти (т.е. что нигде не забыты барьеры). Если гонка есть - укажет на ее характер (RAW/WAR/WAW) и на строки в кернеле (обеих операций участвующих в гонке)

# Ориентиры

В целом достаточно посмотреть на последние коммиты в этой ветке. Особенно на коммит [Translated to CUDA](https://github.com/GPGPUCourse/GPGPUTasks2020/commit/828416ce0b6504cb687a973c0882ce85cb40d396).

Но вот дополнительные ориентиры:

 - [CMakeLists.txt](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/CMakeLists.txt#L28-L32): Поиск CUDA-компилятора, добавление для NVCC компилятора флажка 'сохранять номера строк' (нужно чтобы cuda-memcheck мог указывать номера строк с ошибками), добавление ```src/cu/aplusb.cu``` в список исходников, компиляция через ```cuda_add_executable```.
 - [aplusb.cu](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/cu/aplusb.cu): CUDA-кернел транслируется из OpenCL-кернела посредством [макросов](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/libs/gpu/libgpu/cuda/cu/opencl_translator.cu), вызов кернела через функцию ```cuda_aplusb```
 - [main.cpp](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp): [декларация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L28-L30) функции ```cuda_aplusb```, [инициализация](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L59) CUDA-контекста, [вызов](https://github.com/GPGPUCourse/GPGPUTasks2020/blob/97d32d6405eb9540cd77d760c9e17ed6420fcbaa/src/main_aplusb.cpp#L111) функции вызывающий кернел
