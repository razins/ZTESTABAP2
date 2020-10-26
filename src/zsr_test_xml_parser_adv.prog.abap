*&---------------------------------------------------------------------*
*& Report ZSR_TEST_XML_PARSER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zsr_test_xml_parser_adv.

type-pools: ixml.

*----------------------------------------------------------------------*
*       www.developerpages.gr
*
*     Parse xml file
*----------------------------------------------------------------------*

start-of-selection.

*-- data
  data: pixml          type ref to if_ixml,
        pdocument      type ref to if_ixml_document,
        pstreamfactory type ref to if_ixml_stream_factory,
        pistream       type ref to if_ixml_istream,
        pparser        type ref to if_ixml_parser,
        pnode          type ref to if_ixml_node,
        ptext          type ref to if_ixml_text,
        string         type string,
        count          type i,
        index          type i,
        dsn(40)        type c,
        xstr           type xstring.
  data: stext type string.
  data: gv_count type i.
*-- read the XML document from the frontend machine
  types: begin of xml_line,
           data(256) type x,
         end of xml_line.

  data xml_string type string.
  data xxml_string type xstring.

*  parameters : xml_file TYPE string DEFAULT '\\'.



  data: lv_content  type xstring,
        lo_document type ref to cl_docx_document.

  data:lv_file type string value 'd:\word.docx'
      , lt_data_tab     type standard table of x255
      , lw_length       type i
  .
*    call TRANSFORMATION
  cl_gui_frontend_services=>gui_upload(
     exporting
       filename                = lv_file
       filetype                = 'BIN'
*      codepage                = '4110'
*      dat_mode                = 'X'
      importing
        filelength              = lw_length
*      header                  = lv_header
     changing
       data_tab                = lt_data_tab
     exceptions
       others                  = 99 ).
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
               with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'SCMS_BINARY_TO_XSTRING'
    exporting
      input_length = lw_length
    importing
      buffer       = lv_content
    tables
      binary_tab   = lt_data_tab
    exceptions
      others       = 2.

*exit.
*perform get_doc_binary using 'C:\Users\i042416\Desktop\test.docx' changing lv_content.
  lo_document = cl_docx_document=>load_document( lv_content ).
  check lo_document is not initial.
  data(lo_core_part) = lo_document->get_corepropertiespart( ).
  data(lv_core_data) = lo_core_part->get_data( ).
  data(lo_main_part) = lo_document->get_maindocumentpart( ).

  xxml_string = lo_main_part->get_data( ).


** Load file
*  perform load_file.

* parse xml
  perform parse_xml.
  break-point .

*&---------------------------------------------------------------------*
*&      Form  load_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*form load_file.
*
*  DATA line TYPE string.
*  clear xml_string.
*
*  OPEN DATASET xml_file IN TEXT MODE for input ENCODING UTF-8 .
*  if sy-subrc = 0.
*    DO.
*      READ DATASET xml_file INTO line.
*      IF sy-subrc <> 0.
*        EXIT.
*      else.
*        CONCATENATE xml_string line INTO xml_string.
*      ENDIF.
*    ENDDO.
*    if xml_string is initial.
*      write :/ 'file is empty ! ', xml_file.
*    endif.
*  else.
*    WRITE :/ 'cannot open file ', xml_file.
*  endif.
*
*endform.                    "load_file


*&---------------------------------------------------------------------*
*&      Form  parse_xml
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form parse_xml.

*-- create the main factory
  pixml = cl_ixml=>create( ).

*-- create the initial document
  pdocument = pixml->create_document( ).

*-- create the stream factory
  pstreamfactory = pixml->create_stream_factory( ).

*-- create an input stream for the string
  pistream = pstreamfactory->create_istream_xstring( string = xxml_string ).

*-- create the parser
  pparser = pixml->create_parser( stream_factory = pstreamfactory
                                  istream        = pistream
                                  document       = pdocument ).

*  pparser->add_preserve_space_element( ).

*-- parse the stream
  if pparser->parse( ) ne 0.
    if pparser->num_errors( ) ne 0.
      count = pparser->num_errors( ).
      write: count, ' parse errors have occured:'.
      data: pparseerror type ref to if_ixml_parse_error,
            i           type i.
      index = 0.
      while index < count.
        pparseerror = pparser->get_error( index = index ).
        i = pparseerror->get_line( ).
        write: 'line: ', i.
        i = pparseerror->get_column( ).
        write: 'column: ', i.
        string = pparseerror->get_reason( ).
        write: string.
        index = index + 1.
      endwhile.
    endif.
  endif.

*-- we don't need the stream any more, so let's close it...
  call method pistream->close( ).
  clear pistream.

*-- print the whole DOM tree as a list...
  pnode = pdocument.
  perform process_node using pnode.

endform.                    "parse_xml


*---------------------------------------------------------------------*
*       FORM print_node                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
form process_node using value(pnode) type ref to if_ixml_node.
  data: indent      type i.
  data: ptext       type ref to if_ixml_text.
  data: string      type string.
  data : ss type string.

  data: attribs      type ref to if_ixml_named_node_map,
        attrib_node  type ref to if_ixml_node,
        attrib_value type string.
  add 1 to gv_count.
  if gv_count ge 10000.
    exit.
  endif.
  indent  = pnode->get_height( ) * 2.

  case pnode->get_type( ).
    when if_ixml_node=>co_node_element.
      string = pnode->get_name( ).
      attribs = pnode->get_attributes( ).
      clear attrib_value.
      case string.
        when 'p'.
          write: /.
          stext = stext && cl_abap_char_utilities=>newline."cr_lf.
        when 't'. "put your XML tag name here
          ss = pnode->get_value( ).
        when 'Item'. "put your XML tag name here
          ss = pnode->get_value( ).
          write: / ss.
      endcase.
*      WRITE: AT /indent '<', string, '> '.                  "#EC NOTEXT
    when if_ixml_node=>co_node_text.
      ptext ?= pnode->query_interface( ixml_iid_text ).
*      if ptext->ws_only( ) is initial.
        string = pnode->get_value( ).
        write: string.
        stext = stext && string.
*      endif.
  endcase.
  pnode = pnode->get_first_child( ).

  while not pnode is initial.
    perform process_node using pnode.
    pnode = pnode->get_next( ).
  endwhile.

endform.                    "print_node
