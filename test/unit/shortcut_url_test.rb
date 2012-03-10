require 'test_helper'

class ShortcutUrlTest < ActiveSupport::TestCase
  
  context "a shortcut url" do
    
    setup { @shortcut_url = ShortcutUrl.new }
    subject { @shortcut_url }
    
    should belong_to :shortcut_command
    
    context "having been saved" do
      setup do
        @shortcut_url = ShortcutUrl.find_or_create :shortcut => "This is the first statement title", :human_readable => true, :shortcut_command => {:command => {:operation => "sten1"}}
      end
      
      context "given we want to save a new shortcut with the same title" do
        setup do 
          @new_title = "This is the first statement title"
        end
        
        should "create a new shortcut for a statement with the same title, but with the iterator being used at the end of it" do
          new_shortcut = ShortcutUrl.find_or_create :shortcut => @new_title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten2"}}
          
          assert new_shortcut.valid?
          assert !new_shortcut.eql?(@shortcut_url)
          assert new_shortcut.shortcut.eql? "this-is-the-first-statement-title1"
        end
        
        should "create a new shortcut for the same statement" do
          new_shortcut = ShortcutUrl.find_or_create :shortcut => @new_title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten1"}}
          
          assert new_shortcut.eql?(@shortcut_url)
          assert new_shortcut.shortcut.eql? "this-is-the-first-statement-title"
        end
      end
    end
    context "having been saved with a really long name" do
      setup do
        title = "This is really a long title because its supposed to be this way if you have problems with it buzz off"
        @shortcut_url = ShortcutUrl.find_or_create :shortcut => title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten1"}}
      end
      
      context "given we want to save a new shortcut with the same title" do
        setup do
          @new_title = "This is really a long title because its supposed to be this way if you have problems with it buzz off"
        end
        
        should "create a new shortcut for a statement with the same title, therefore cutting the former" do
          new_shortcut = ShortcutUrl.find_or_create :shortcut => @new_title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten2"}}
          
          assert !new_shortcut.eql?(@shortcut_url)
          assert new_shortcut.shortcut.eql? "this-is-really-a-long-title-because-its-supposed-to-be-this-way-if-you-have-problems-with-it-buzz-of1"
        end
      end
    end
    
    context "having a shortcut with special characters" do
      setup do
        @title = "O cão do João roça à direita do pai"
      end
      
      should "save the shortcut without the special characters" do
        @shortcut_url = ShortcutUrl.find_or_create :shortcut => @title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten2"}}
        
        assert @shortcut_url.shortcut, "o-cao-do-joao-roca-a-direita-do-pai"
      end
    end
  end
  
  context "having been saved with a really big shortcut" do
    setup do
      @title = "O rato roeu a rolha do rei da Russia atirei o pau ao gato to mas o gato to nao morreu eu eu dona Xica ca assustou-se se com o berro que o gato deu"
      @shortcut_url = ShortcutUrl.find_or_create :shortcut => @title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten1"}}
    end
    
    should "cut the title with the appropriate size" do
      assert @shortcut_url.shortcut.length, 101
      assert @shortcut_url.shortcut, @title.downcase[0, 101].gsub(/\s/, "-")
    end
  end
  context "having been saved with special characters" do
    setup do
      @title = "Mas quem sou eu? O bom, o mau ou o vilão?"
      @shortcut_url = ShortcutUrl.find_or_create :shortcut => @title, :human_readable => true, :shortcut_command => {:command => {:operation => "sten1"}}
    end
    
    should "cut the special characters" do
      assert @shortcut_url.shortcut, "mas-quem-sou-eu-o-bom-o-mau-ou-o-vilao"
    end
  end
end
