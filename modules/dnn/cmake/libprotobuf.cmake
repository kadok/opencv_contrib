include(CheckIncludeFiles)
include(cmake/CheckCxxHashset.cmake)
include(cmake/CheckCxxHashmap.cmake)

check_include_files("pthread.h" HAVE_PTHREAD)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  include(CheckIncludeFileCXX)
  set(CMAKE_REQUIRED_FLAGS "-std=c++11")
  check_include_file_cxx("unordered_map" HAVE_UNORDERED_MAP)
  check_include_file_cxx("tr1/unordered_map" HAVE_TR1_UNORDERED_MAP)
  set(CMAKE_REQUIRED_FLAGS )

  if(HAVE_UNORDERED_MAP)
    add_definitions("-std=c++11") # For unordered_map
    set(HASH_MAP_H "<unordered_map>")
    set(HASH_MAP_CLASS "unordered_map")
    set(HASH_NAMESPACE "std")
    set(HAVE_HASH_MAP 1)
  elseif(HAVE_TR1_UNORDERED_MAP)
    add_definitions("-std=c++11") # For unordered_map
    set(HASH_MAP_H "<tr1/unordered_map>")
    set(HASH_MAP_CLASS "unordered_map")
    set(HASH_NAMESPACE "std::tr1")
    set(HAVE_HASH_MAP 1)
  else()
    CHECK_HASHMAP()
    if(HAVE_GNU_EXT_HASH_MAP)
      set(HASH_MAP_H "<ext/hash_map>")
      set(HASH_NAMESPACE "__gnu_cxx")
      set(HASH_MAP_CLASS "hash_map")
      set(HAVE_HASH_MAP 1)
    elseif(HAVE_STD_EXT_HASH_MAP)
      set(HASH_MAP_H "<ext/hash_map>")
      set(HASH_NAMESPACE "std")
      set(HASH_MAP_CLASS "hash_map")
      set(HAVE_HASH_MAP 1)
    elseif(HAVE_GLOBAL_HASH_MAP)
      set(HASH_MAP_H "<ext/hash_map>")
      set(HASH_NAMESPACE "")
      set(HASH_MAP_CLASS "hash_map")
      set(HAVE_HASH_MAP 1)
    else()
      set(HAVE_HASH_MAP 0)
    endif()
  endif()

  set(CMAKE_REQUIRED_FLAGS "-std=c++11")
  check_include_file_cxx("unordered_set" HAVE_UNORDERED_SET)
  check_include_file_cxx("tr1/unordered_set" HAVE_TR1_UNORDERED_SET)
  set(CMAKE_REQUIRED_FLAGS )

  if(HAVE_UNORDERED_SET)
    set(HASH_SET_H "<unordered_set>")
    set(HASH_SET_CLASS "unordered_set")
    set(HAVE_HASH_SET 1)
  elseif(HAVE_TR1_UNORDERED_SET)
    add_definitions("-std=c++11")
    set(HASH_SET_H "<tr1/unordered_set>")
    set(HASH_SET_CLASS "unordered_set")
    set(HAVE_HASH_SET 1)
  else()
    CHECK_HASHSET()
    if(HAVE_GNU_EXT_HASH_SET)
      set(HASH_SET_H "<ext/hash_set>")
      set(HASH_NAMESPACE "__gnu_cxx")
      set(HASH_SET_CLASS "hash_set")
      set(HAVE_HASH_SET 1)
    elseif(HAVE_STD_EXT_HASH_SET)
      set(HASH_SET_H "<ext/hash_set>")
      set(HASH_NAMESPACE "std")
      set(HASH_SET_CLASS "hash_set")
      set(HAVE_HASH_SET 1)
    elseif(HAVE_GLOBAL_HASH_SET)
      set(HASH_SET_H "<hash_set>")
      set(HASH_NAMESPACE "")
      set(HASH_SET_CLASS "hash_set")
      set(HAVE_HASH_SET 1)
    else()
      set(HAVE_HASH_SET 0)
    endif()
  endif()
endif()

if(WIN32 AND BUILD_SHARED_LIBS AND MSVC)
    add_definitions(-DPROTOBUF_USE_DLLS)
    add_definitions(-DLIBPROTOBUF_EXPORTS)
endif()

add_definitions( -D_GNU_SOURCE=1 )
add_definitions( -DHAVE_CONFIG_H )
configure_file("cmake/libporobuf_config.h.in" "config.h")

if(MSVC)
  add_definitions( -D_CRT_SECURE_NO_WARNINGS=1 )
  ocv_warnings_disable(CMAKE_CXX_FLAGS /wd4244 /wd4267 /wd4018 /wd4355 /wd4800 /wd4251 /wd4996 /wd4146 /wd4305)
else()
  ocv_warnings_disable(CMAKE_CXX_FLAGS -Wno-deprecated -Wunused-parameter -Wunused-local-typedefs -Wsign-compare -Wundef)
endif()

# Easier to support different versions of protobufs
function(append_if_exist OUTPUT_LIST)
    set(${OUTPUT_LIST})
    foreach(fil ${ARGN})
        if(EXISTS ${fil})
            list(APPEND ${OUTPUT_LIST} "${fil}")
        else()
            message("Warning: file missing: ${fil}")
        endif()
    endforeach()
    set(${OUTPUT_LIST} ${${OUTPUT_LIST}} PARENT_SCOPE)
endfunction()

set(PROTOBUF_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/protobuf)

append_if_exist(PROTO_SRCS
  ${PROTOBUF_ROOT}/src/google/protobuf/compiler/importer.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/compiler/parser.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/descriptor.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/descriptor.pb.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/descriptor_database.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/dynamic_message.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/extension_set.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/extension_set_heavy.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/generated_message_reflection.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/generated_message_util.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/coded_stream.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/gzip_stream.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/printer.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/tokenizer.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/zero_copy_stream.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/zero_copy_stream_impl.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/io/zero_copy_stream_impl_lite.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/message.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/message_lite.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/reflection_ops.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/repeated_field.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/service.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/atomicops_internals_x86_gcc.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/atomicops_internals_x86_msvc.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/common.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/once.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/stringprintf.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/structurally_valid.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/strutil.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/substitute.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/text_format.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/unknown_field_set.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/wire_format.cc
  ${PROTOBUF_ROOT}/src/google/protobuf/wire_format_lite.cc
#  ${PROTOBUF_ROOT}/src/google/protobuf/stubs/hash.cc
)