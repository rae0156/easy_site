module PDFHelper
  # -----------------------
  # Create the title page -
  # -----------------------
  def create_title_page(pdf, title, subtitle = nil)
    # Insert the background

#    file_pdf_background = "public/images/pdf_background.png"
#    pdf.image(file_pdf_background, :justification => :center, :scale => 0.55) 


    file_pdf_background = EsSetup.get_setup("image_header_pdf","") #File.join(Rails.root,'app','assets','images','rails.png')
    pdf.image(File.join(Rails.root,file_pdf_background), :scale => 0.5) unless file_pdf_background.blank?


    pdf.fill_color("0060A9")
    # Write the title
    pdf.font_size 28
    pdf.text_box title, :at => [55, 500] #450

    pdf.fill_color("000000")
  
    # Write the subtitle
    if (!subtitle.nil?)
      pdf.font_size 16
      pdf.text_box subtitle, :at => [55, 455]  #425
    end
 
    # Set back the text color to black
    pdf.fill_color("000000")
  
  end
end