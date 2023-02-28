require File.dirname(__FILE__) + '/../test_helper'

class RequestsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:requests)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_request
    assert_difference('Request.count') do
      post :create, :request => { }
    end

    assert_redirected_to request_path(assigns(:request))
  end

  def test_should_show_request
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_request
    put :update, :id => 1, :request => { }
    assert_redirected_to request_path(assigns(:request))
  end

  def test_should_destroy_request
    assert_difference('Request.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to requests_path
  end
end
