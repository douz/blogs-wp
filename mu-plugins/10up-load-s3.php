<?php
/**
 * Plugin Name:  10up - S3 Uploads compatibility
 * Description:  Load Composer dependencies and configure S3 Uploads
 * Author:       10up, Felipe Elia
 * Author URI:   https://10up.com
 * License:      MIT
 *
 * @package TenUp
 */

namespace TenUp\LoadS3;

/**
 * Load root Composer dependencies before regular plugins initialize.
 */
function load_composer_dependencies() {
	$autoload_file = WP_CONTENT_DIR . '/vendor/autoload.php';

	if ( ! file_exists( $autoload_file ) ) {
		return;
	}

	require_once $autoload_file;
}
add_action( 'muplugins_loaded', __NAMESPACE__ . '\load_composer_dependencies' );

/**
 * Use CF R2 instead of AWS S3.
 */
function set_cloudflare_endpoint( $params ) {
	$params['endpoint'] = 'https://43b858bd5a5da0cd1b0651745e770fff.r2.cloudflarestorage.com';
	$params['use_path_style_endpoint'] = true;
	$params['debug'] = false; // Set to true if uploads are failing.
	return $params;
}
add_filter( 's3_uploads_s3_client_params', __NAMESPACE__ . '\set_cloudflare_endpoint' );
