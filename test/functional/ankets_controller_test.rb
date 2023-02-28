require File.dirname(__FILE__) + '/../test_helper'

class AnketsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:ankets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_anket
    assert_difference('Anket.count') do
      post :create, :anket => { }
    end

    assert_redirected_to anket_path(assigns(:anket))
  end

  def test_should_show_anket
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_anket
    put :update, :id => 1, :anket => { }
    assert_redirected_to anket_path(assigns(:anket))
  end

  def test_should_destroy_anket
    assert_difference('Anket.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to ankets_path
  end
end
