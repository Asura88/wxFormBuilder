function(add_plugin PLUGIN_NAME)
  set(options "")
  set(singleValues DIRECTORY)
  set(multiValues SOURCES DEFINITIONS LIBRARIES COMPONENTS ICONS)
  cmake_parse_arguments(PLUGIN "${options}" "${singleValues}" "${multiValues}" ${ARGN})

  if(NOT DEFINED PLUGIN_DIRECTORY)
    set(PLUGIN_DIRECTORY ${PLUGIN_NAME})
  endif()
  if(DEFINED PLUGIN_SOURCES)
    list(TRANSFORM PLUGIN_SOURCES PREPEND ${PLUGIN_DIRECTORY}/)
  endif()
  if(NOT DEFINED PLUGIN_COMPONENTS)
    set(PLUGIN_COMPONENTS ${PLUGIN_NAME})
  endif()

  add_library(wxFormBuilder_${PLUGIN_NAME} MODULE)
  add_library(wxFormBuilder::${PLUGIN_NAME} ALIAS wxFormBuilder_${PLUGIN_NAME})
  set_target_properties(wxFormBuilder_${PLUGIN_NAME} PROPERTIES
      OUTPUT_NAME ${PLUGIN_NAME}
  )

  target_sources(wxFormBuilder_${PLUGIN_NAME}
    PRIVATE
      ${PLUGIN_DIRECTORY}/${PLUGIN_NAME}.cpp
  )
  if(DEFINED PLUGIN_SOURCES)
    target_sources(wxFormBuilder_${PLUGIN_NAME}
      PRIVATE
        ${PLUGIN_SOURCES}
    )
  endif()
  if(DEFINED PLUGIN_DEFINITIONS)
    target_compile_definitions(wxFormBuilder_${PLUGIN_NAME}
      PRIVATE
        ${PLUGIN_DEFINITIONS}
    )
  endif()
  target_link_libraries(wxFormBuilder_${PLUGIN_NAME}
    PUBLIC
      wxFormBuilder::plugin-interface
  )
  if(DEFINED PLUGIN_LIBRARIES)
    target_link_libraries(wxFormBuilder_${PLUGIN_NAME}
      PRIVATE
        ${PLUGIN_LIBRARIES}
    )
  endif()

  if(APPLE)
    set_target_properties(wxFormBuilder_${PLUGIN_NAME} PROPERTIES
      INSTALL_RPATH "@loader_path/../Frameworks"
    )
  else()
    set_target_properties(wxFormBuilder_${PLUGIN_NAME} PROPERTIES
      INSTALL_RPATH $ORIGIN/..
    )
  endif()

  # TODO: Use cache variable for these
  set(generatorLanguages cpp python lua php)

  # TODO: In the final sources layout these files should reside next to the sources
  set(sourceDir "${CMAKE_CURRENT_SOURCE_DIR}/../output/plugins/${PLUGIN_DIRECTORY}/xml")
  set(destDir "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_DATADIR}/plugins/${PLUGIN_NAME}/xml")
  set(definitionsSource "")
  set(definitionsDest "")
  set(templatesSource "")
  set(templatesDest "")
  foreach(component IN LISTS PLUGIN_COMPONENTS)
    list(APPEND definitionsSource "${sourceDir}/${component}.xml")
    list(APPEND definitionsDest "${destDir}/${component}.xml")
    foreach(lang IN LISTS generatorLanguages)
      list(APPEND templatesSource "${sourceDir}/${component}.${lang}code")
      list(APPEND templatesDest "${destDir}/${component}.${lang}code")
    endforeach()
  endforeach()

  add_custom_command(OUTPUT ${definitionsDest} COMMENT "wxFormBuilder_${PLUGIN_NAME}: Copying component definitions")
  foreach(source dest IN ZIP_LISTS definitionsSource definitionsDest)
    add_custom_command(
      OUTPUT ${definitionsDest}
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${source}" "${dest}"
      DEPENDS "${source}"
      VERBATIM
      APPEND
    )
  endforeach()
  add_custom_target(wxFormBuilder_${PLUGIN_NAME}-definitions
    DEPENDS ${definitionsDest}
  )

  add_custom_command(OUTPUT ${templatesDest} COMMENT "wxFormBuilder_${PLUGIN_NAME}: Copying code templates")
  foreach(source dest IN ZIP_LISTS templatesSource templatesDest)
    add_custom_command(
      OUTPUT ${templatesDest}
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${source}" "${dest}"
      DEPENDS "${source}"
      VERBATIM
      APPEND
    )
  endforeach()
  add_custom_target(wxFormBuilder_${PLUGIN_NAME}-templates
    DEPENDS ${templatesDest}
  )

  add_dependencies(wxFormBuilder_${PLUGIN_NAME}
    wxFormBuilder_${PLUGIN_NAME}-definitions
    wxFormBuilder_${PLUGIN_NAME}-templates
  )

  if(DEFINED PLUGIN_ICONS)
    # TODO: In the final sources layout these files should reside next to the sources  
    set(sourceDir "${CMAKE_CURRENT_SOURCE_DIR}/../output/plugins/${PLUGIN_DIRECTORY}/icons")
    set(destDir "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_DATADIR}/plugins/${PLUGIN_NAME}/icons")
    set(iconsSource "")
    set(iconsDest "")
    foreach(icon IN LISTS PLUGIN_ICONS)
      list(APPEND iconsSource "${sourceDir}/${icon}")
      list(APPEND iconsDest "${destDir}/${icon}")
    endforeach()

    add_custom_command(OUTPUT ${iconsDest} COMMENT "wxFormBuilder_${PLUGIN_NAME}: Copying icons")
    foreach(source dest IN ZIP_LISTS iconsSource iconsDest)
      add_custom_command(
        OUTPUT ${iconsDest}
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${source}" "${dest}"
        DEPENDS "${source}"
        VERBATIM
        APPEND
      )
    endforeach()
    add_custom_target(wxFormBuilder_${PLUGIN_NAME}-icons
      DEPENDS ${iconsDest}
    )

    add_dependencies(wxFormBuilder_${PLUGIN_NAME}
      wxFormBuilder_${PLUGIN_NAME}-icons
    )
  endif()

  if(WIN32)
    # TODO: Using RUNTIME_DEPENDENCIES results in the dependencies getting installed in the locations
    #       defined in this command, this is however unwanted because they should get installed in
    #       the global location. Registering the dependencies in a set and installing them later with
    #       the standalone command has the desired effect, but why?
    install(TARGETS wxFormBuilder_${PLUGIN_NAME}
      RUNTIME_DEPENDENCY_SET wxFormBuilder_deps
      RUNTIME
        DESTINATION ${CMAKE_INSTALL_BINDIR}/plugins/${PLUGIN_NAME}
      LIBRARY
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/plugins/${PLUGIN_NAME}
    )
  elseif(APPLE)
    install(TARGETS wxFormBuilder_${PLUGIN_NAME}
      RUNTIME
        DESTINATION wxFormBuilder.app/Contents/PlugIns
      LIBRARY
        DESTINATION wxFormBuilder.app/Contents/PlugIns
    )
  else()
    install(TARGETS wxFormBuilder_${PLUGIN_NAME}
      RUNTIME
        DESTINATION ${CMAKE_INSTALL_BINDIR}/wxformbuilder
      LIBRARY
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/wxformbuilder
    )
  endif()

  # TODO: In the final sources layout these files should reside next to the sources
  install(FILES ${definitionsSource}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/plugins/${PLUGIN_NAME}/xml
  )
  install(FILES ${templatesSource}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/plugins/${PLUGIN_NAME}/xml
  )
  if(DEFINED PLUGIN_ICONS)
    install(DIRECTORY ../output/plugins/${PLUGIN_DIRECTORY}/icons
      DESTINATION ${CMAKE_INSTALL_DATADIR}/plugins/${PLUGIN_NAME}
    )
  endif()
endfunction()
