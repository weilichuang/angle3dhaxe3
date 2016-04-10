package org.angle3d.asset.cache;

/**
 * AssetCache is an interface for asset caches. 
 * Allowing storage of loaded resources in order to improve their access time 
 * if they are requested again in a short period of time.
 * Depending on the asset type and how it is used, a specialized 
 * caching method can be selected that is most appropriate for that asset type.
 * The asset cache must be thread safe.
 * <p>
 * Some caches are used to manage cloneable assets, which track reachability
 * based on a shared key in all instances exposed in user code. 
 * E.g. {WeakRefCloneAssetCache} uses this approach.
 * For those particular caches, either `registerAssetClone`
 * or `notifyNoAssetClone` <b>MUST</b> be called to avoid memory 
 * leaking following a successful `addToCache`
 * or `getFromCache` call!
 * 
 * 
 */
interface AssetCache<T> 
{
  /**
     * Adds an asset to the cache.
     * Once added, it should be possible to retrieve the asset
     * by using the `getFromCache` method.
     * However the caching criteria may at some point choose that the asset
     * should be removed from the cache to save memory, in that case, 
     * `getFromCache` will return null.
     * <p><font color="red">Thread-Safe</font>
     * 
     * @param <T> The type of the asset to cache.
     * @param key The asset key that can be used to look up the asset.
     * @param obj The asset data to cache.
     */
    function addToCache(key:AssetKey, obj:T):Void;
    
    /**
     * This should be called by the asset manager when it has successfully
     * acquired a cached asset (with {#getFromCache(org.angle3d.asset.AssetKey) })
     * and cloned it for use. 
     * @param <T> The type of the asset to register.
     * @param key The asset key of the loaded asset (used to retrieve from cache)
     * @param clone The <strong>clone</strong> of the asset retrieved from
     * the cache.
     */
    function registerAssetClone(key:AssetKey, clone:T):Void;
    
    /**
     * Notifies the cache that even though the methods `addToCache`
     * or `getFromCache` were used, there won't
     * be a call to `registerAssetClone`
     * for some reason. For example, if an error occurred during loading
     * or if the addToCache/getFromCache were used from user code.
     */
    function notifyNoAssetClone():Void;
    
    /**
     * Retrieves an asset from the cache.
     * It is possible to add an asset to the cache using
     * `addToCache`. 
     * The asset may be removed from the cache automatically even if
     * it was added previously, in that case, this method will return null.
     * @param <T> The type of the asset to retrieve
     * @param key The key used to lookup the asset.
     * @return The asset that was previously cached, or null if not found.
     */
    function getFromCache(key:AssetKey):T;
    
    /**
     * Deletes an asset from the cache.
     * @param key The asset key to find the asset to delete.
     * @return True if the asset was successfully found in the cache
     * and removed.
     */
    function deleteFromCache(key:AssetKey):Bool;
    
    /**
     * Deletes all assets from the cache.
     */
    function clearCache():Void;
}