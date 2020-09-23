
cmake_minimum_required(VERSION 3.18)

project(Camtimers)
enable_language(C Fortran)

option(CAMTIMERS_USE_NVTX "use_nvtx" OFF)

find_package(MPI REQUIRED)
find_package(OpenMP)

if (CAMTIMERS_USE_NVTX)
  find_package(CUDAToolkit REQUIRED)
endif()

# Clone the perfstubs repo if it doesn't exist

if(NOT EXISTS "${PROJECT_SOURCE_DIR}/perfstubs/CMakeLists.txt")
include(cmake/GitUtils.cmake)
git_clone(
        PROJECT_NAME    perfstubs
        GIT_URL         https://github.com/khuck/perfstubs.git
        GIT_BRANCH      master
        DIRECTORY       ${PROJECT_SOURCE_DIR}
)
endif(NOT EXISTS "${PROJECT_SOURCE_DIR}/perfstubs/CMakeLists.txt")

# configure a header file to pass some of the CMake settings
# to the source code
if(NOT EXISTS "${PROJECT_SOURCE_DIR}/perfstubs/perfstubs_api/config.h")
set (PerfStubs_VERSION_MAJOR 0)
set (PerfStubs_VERSION_MINOR 1)
configure_file (
    "${PROJECT_SOURCE_DIR}/perfstubs/perfstubs_api/config.h.in"
    "${PROJECT_SOURCE_DIR}/perfstubs/perfstubs_api/config.h"
)
endif(NOT EXISTS "${PROJECT_SOURCE_DIR}/perfstubs/perfstubs_api/config.h")

# The easiest way to include perfstubs support is to include the one source file in
# the camtimers library.

add_library(timers
  perfstubs/perfstubs_api/timer.c
  f_wrappers.c
  GPTLget_memusage.c
  GPTLprint_memusage.c
  gptl.c
  gptl_papi.c
  GPTLutil.c
  perf_mod.F90
  perf_utils.F90)

target_compile_definitions(timers PRIVATE FORTRANUNDERSCORE HAVE_MPI LINUX PERFSTUBS_USE_TIMERS)
target_link_libraries(timers PUBLIC MPI::MPI_C "${CMAKE_DL_LIBS}") # global_settings)
if(OpenMP_FOUND)
    target_link_libraries(timers PRIVATE OpenMP::OpenMP_C)
    target_link_libraries(timers PRIVATE OpenMP::OpenMP_Fortran)
endif(OpenMP_FOUND)
target_include_directories(timers PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/perfstubs)

if(CAMTIMERS_USE_NVTX)
  target_compile_definitions(timers PRIVATE HAVE_NVTX)
  target_link_libraries(timers PRIVATE CUDA::nvToolsExt)
endif()

install(TARGETS timers)
install (FILES gptl.h DESTINATION include)
install (FILES ${CMAKE_BINARY_DIR}/perf_mod.mod DESTINATION include)
install (FILES ${CMAKE_BINARY_DIR}/perf_utils.mod DESTINATION include)

# provide under CAMTIMERS::CAMTIMERS name
add_library(CAMTIMERS::CAMTIMERS INTERFACE IMPORTED GLOBAL)
target_link_libraries(CAMTIMERS::CAMTIMERS INTERFACE timers)

add_executable(example1 example1.F90)
target_link_libraries(example1 PRIVATE CAMTIMERS::CAMTIMERS MPI::MPI_Fortran)
